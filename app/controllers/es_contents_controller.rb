# encoding: UTF-8

class EsContentsController < ApplicationController

  def list
    sorting :default => 'es_contents.name, es_content_details.sequence'
    session[:conditions_content] = create_conditions
    @contents = EsContentDetail.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_content], :include => :es_content

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'content_div', 'list'
        render 'shared/replace_content'
      end
    end
  end

  def move_up
    id = params[:id]
    content_detail = EsContentDetail.find_by_id(id)
    content_detail.update_attribute('sequence',content_detail.sequence - 1.5)
    content_detail.es_content.compress_detail
    redirect_to :action => "list" 
  end
  
  def move_down
    id = params[:id]
    content_detail = EsContentDetail.find_by_id(id)
    content_detail.update_attribute('sequence',content_detail.sequence + 1.5)
    content_detail.es_content.compress_detail
    redirect_to :action => "list" 
  end

  def new
    @from_action = "new"
    @content = EsContentDetail.new(:sequence => 1)    
  end
  
  def add
    @from_action = "add"
    id = params[:id]
    tmp_content = EsContentDetail.find_by_id(id)
    @content = EsContentDetail.new(:es_content_id => tmp_content.es_content_id, :sequence => tmp_content.sequence + 1)
    render :action  => 'new'
  end
  
  def create
    @from_action = params[:from_action]
    name = params[:content].delete(:name)
    @content = EsContentDetail.new(params[:content])
    @content.content  = ""
    @content.editable = EsContent::EDITABLE_CONTENT_TYPES.include?(@content.content_type) ? "Y" : "N"
    content = EsContent.find_by_name(name)
    if content
      @content.es_content_id = content.id
    else
      @content.es_content = EsContent.new(:name => name)
    end

    
    if @content.save
      if @content.content_type == EsContent::CONTENT_TYPES_MODULE
        module_action_name = @content.module_action_name.split(' ')
        @content.content = "<%= generate_module_part(" + '"' + module_action_name[0] + '","' + module_action_name[1] + '"' + ",#{@content.id})%>"
        @content.save
      elsif @content.content_type == EsContent::CONTENT_TYPES_DYNAMIC
        @content.content = "<%= generate_dynamic_part(#{@content.id})%>"
        @content.save
      end
      flash[:notice] = "Le contenu '%{name}' a été créé.".trn(:name => @content.name)
      redirect_to :action => :list
    else
      render :action  => 'new'
    end
  end
  
  def edit
    id = params[:id]
    @content = EsContentDetail.find_by_id(id)
  end

  def update
    id = params[:id]
    @content = EsContentDetail.find_by_id(id)
    if EsContent.find(:first,:conditions => ["id <> ? AND name = ?",@content.es_content.id,params[:content][:name]])
      @content.errors.add(:name, "#Ce nom de contenu '%{name}' existe déjà.".trn(:name => params[:content][:name])) 
    else
      escontent = @content.es_content
    end
    @content.attributes = params[:content]
    escontent.attributes = {:name => params[:content][:name]}
    if @content.content_type == EsContent::CONTENT_TYPES_MODULE
      module_action_name = @content.module_action_name.split(' ')
      @content.content = "<%= generate_module_part(" + '"' + module_action_name[0] + '","' + module_action_name[1] + '"' + ",#{@content.id})%>"
    elsif @content.content_type == EsContent::CONTENT_TYPES_DYNAMIC
      @content.content = "<%= generate_dynamic_part(#{@content.id})%>"
    end

    @content.valid? if @content.errors.empty?

    if @content.errors.empty? 
      escontent.save
      @content.save
      flash[:notice] = "Le contenu '%{name}' a été correctement modifié.".trn(:name => @content.name)
      redirect_to :action => :list
    else
      render :action => 'edit'
    end
  end

  def destroy
    tmp_element_error = EsContentDetail.new
    tmp = EsContentDetail.find(params[:id])
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "Contenu '%{name}' : %{error}.".trn(:name => tmp.name, :error => tmp_error))
        end
      else
        content = EsContent.find_by_name(name)
        if content
          if content.es_content_details.size == 0
            content.destroy
          else
            content.compress_detail
          end 
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "Le contenu '%{name}' a correctement été supprimé.".trn(:name => name)
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end


  def export_csv
    sorting :default => 'es_contents.name, es_content_details.sequence'
    contents = EsContentDetail.find :all, :conditions => session[:conditions_template], :order => @sort, :include => :es_content
    file_name = "contents_export.csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Nom du contenu".trn,"Séquence".trn,"Editable".trn,"Type de contenu".trn,"Utilisé".trn]
       contents.each do |t|
          csv << [t.es_content.name,t.sequence.to_i,t.editable,t.content_type,t.used? ? "Y" : "N"]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end

  def dynamic_content
    session[:dynamic_content_view_normal]=false
    @content_detail_id = params[:id]
    contentdetail = EsContentDetail.find(@content_detail_id)
    if contentdetail
      @content_detail = contentdetail
    else
      redirect_to :action => "list"
    end
  end

  def change_dynamic_content_view
    session[:dynamic_content_view_normal] = !session[:dynamic_content_view_normal] 

    id = params[:id]
    @content_detail = EsContentDetail.find_by_id(id)
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'dynamic_content', 'dynamic_content'
        render 'shared/replace_content'
      end
    end    
  end


  def update_dynamic_content_parts
    id = params[:id]
    @content_detail = EsContentDetail.find_by_id(id)
    
    @content_detail.save_design(params[:parts]) if params[:parts].present?
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        
        if params[:parts].present?
          flash[:message_ajax] = "La disposition des parties du contenu '%{name}' a été correctement sauvée.".trn(:name => @content_detail.name)
          @element_id, @partial = ['dynamic_content','message_ajax'], ['dynamic_content','layouts/part_message_ajax']
        else
          @element_id, @partial = 'dynamic_content', 'dynamic_content'
        end
        render 'shared/replace_content'
      end
    end    
  end

  def design_content
    @content_detail_id = params[:id]
    contentdetail = EsContentDetail.find(@content_detail_id)
    if contentdetail
      @content_tiny = contentdetail.content
      @content_detail_text = "#{contentdetail.name.humanize} : #{contentdetail.content_detail_name}"
    else
      redirect_to :action => "list"
    end
  end

  def update_element_parts
    @content_detail_element = EsContentDetailElement.find_by_id(params[:id])
    if @content_detail_element
      @content_detail = @content_detail_element.es_content_detail
      @content_detail_element.attributes = params[:content_detail_element]
      
      element = EsContent.save_properties("EsContentDetailElement"+@content_detail_element.element_type.classify, @content_detail_element.id, params["generated"])
      detail_element_valid = @content_detail_element.valid? #pour forcer la vérif de @content_detail_element
      if element.errors.empty? && detail_element_valid 
        @content_detail_element.save
        if params[:generated].present? && @content_detail_element.element_type=='module' && !@content_detail_element.es_content_detail_child_id.nil?
          @content_detail_element.es_content_detail_child.save_module_params(params[:generated]) 
        end
        flash[:message_ajax] = "Les propriétés de la partie '%{name}' ont été correctement sauvées.".trn(:name => @content_detail_element.name)
        @content_detail_element = nil 
      else
        @temp_attributes =params["generated"]
        element.errors.full_messages.each do |m|
          @content_detail_element.errors.add(:base, m) 
        end
      end
    
    end
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'dynamic_content', 'dynamic_content'
        render 'shared/replace_content'
      end
    end    
  end

  def delete_element_parts(force_id=nil)
    
    if force_id.blank?
      id_to_delete = params[:id]
    else
      id_to_delete = force_id
    end
    tmp_element = EsContentDetailElement.find_by_id(id_to_delete)
    content_detail_element = ("EsContentDetailElement"+tmp_element.element_type.classify).constantize.find_by_id(id_to_delete)
    if content_detail_element
      if force_id.blank?
        @content_detail = tmp_element.es_content_detail if content_detail_element
      end

      name = content_detail_element.name
      EsContentDetailElement.where(:parent_id => tmp_element.id).each do |e|
        e.update_attribute('parent_id',-1)
        if e.element_type=='structured_child'
          e.update_attribute('element_type',"parent")
          delete_element_parts(e.id)
        end           
      end
      
      tmp_element.es_content_detail_child.destroy if tmp_element.es_content_detail_child
      
      content_detail_element.destroy 
      content_detail_element = nil
      
      flash[:message_ajax] = "La partie '%{name}' a été correctement supprimée.".trn(:name => name) 
    end
    
    if force_id.blank?
      @content_detail_element = ("EsContentDetailElement"+tmp_element.element_type.classify).constantize.find_by_id(id_to_delete)
      
      respond_to do |format|
        format.html {} # Do nothing, so Rails will render the view list.rhtml
        format.js do 
          @element_id, @partial = 'dynamic_content', 'dynamic_content'
          render 'shared/replace_content'
        end
      end    
    end
  end

  def edit_element_parts
    @content_detail_element = EsContentDetailElement.find(params[:id])
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'element_properties', 'element_properties'
        render 'shared/replace_content'
      end
    end    
  end

  def setup_module
    @contentdetail = EsContentDetail.find(params[:id])
    @module_action_name = @contentdetail.module_action_name.split(' ')
    @contentdetail.create_module_params(EsModule.get_module_params(@module_action_name[0],@module_action_name[1]))
  end

  def update_setup_module
    EsContentDetail.find(params[:id]).save_module_params(params[:generated]) if params[:generated].present?
    flash[:notice] = "Les paramètres ont été sauvés.".trn
#    redirect_to :action => "setup_module",:id => params[:id]
    redirect_to :action => "list"
  end

  def clear_properties
    element_type  = params[:element_type]
    element_id    = params[:element_id]
    EsContent.delete_all_properties(element_type, element_id)
    flash[:notice] = "Les propriétés ont été supprimées.".trn
    redirect_to :controller => params[:previous_controller], :action => params[:previous_action], :id => params[:previous_id]
  end

  def edit_properties
    @element_type     = params[:element]
    @element_id       = params[:id]    
    @element          = EsContent.new
    @init_properties  = {}
    
    init_edit_properties(@element_type)
    
  end
  
  def save_properties
    
    element_type  = params[:element][:type]
    element_id    = params[:element][:id]
    
    @element = EsContent.save_properties(element_type, element_id, params["generated"])
    
        
    if @element.errors.empty? 
      flash[:notice] = "Les propriétés ont été correctement sauvées.".trn
      redirect_to :controller => params[:previous_controller], :action => params[:previous_action], :id => params[:previous_id]
    else
      @element_type=element_type
      @element_id=element_id
      @generated=init_edit_properties(@element_type)
      @generated.attributes =params["generated"]
      @init_properties = params["generated"]
       
      render :action => 'edit_properties', :element => element_type, :id => element_id
    end
  end


  def add_element
    id = params[:id]
    element_type        = params[:element_type]
    module_action_name  = params[:content_module_action_name]
    strutured_parent    = params[:content_strutured_parent]
    table_col           = params[:content_table_col]
    table_lin           = params[:content_table_lin]
    @content_detail = EsContentDetail.find_by_id(id)
    if element_type=='module' && module_action_name.blank? 
      flash[:error_message_ajax] = "Vous devez sélectionner un module.".trn 
    elsif element_type=='structured' && strutured_parent.blank?
      flash[:error_message_ajax] = "Vous devez sélectionner un structure de parent.".trn 
    elsif element_type=='table' && (table_col.blank? || table_lin.blank?)
      flash[:error_message_ajax] = "Vous devez sélectionner un nombre de colonnes et de lignes.".trn 
    else
      @content_detail.add_element(element_type,{:module_action_name => module_action_name, :strutured_parent => strutured_parent, :table_col => table_col, :table_lin => table_lin})
    end
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'dynamic_content', 'dynamic_content'
        render 'shared/replace_content'
      end
    end    
  end


private


  def init_edit_properties(element_type)
    element=nil
    case element_type
      when "EsTemplateLine"
        element=EsTemplateLine.find(@element_id)
        @element_name = "template '%{name}' ligne numéro %{num}".trn(:name=> element.es_template.name,:num=> element.num.to_i)
        @previous_controller,@previous_action,@previous_id = "es_templates","design",element.es_template.id
      when "EsTemplateCol"
        element=EsTemplateCol.find(@element_id)
        @element_name = "template '%{name}' ligne numéro %{num_line} colonne numéro %{num}".trn(:name => element.es_template_line.es_template.name, :num_line => element.es_template_line.num.to_i, :num=> element.num)
        @previous_controller,@previous_action,@previous_id = "es_templates","design",element.es_template_line.es_template.id
      when "EsContentDetail"
        element=EsContentDetail.find(@element_id)
        @element_name = "contenu %{name} séquence %{num}".trn(:name => element.es_content.name,:num=> element.sequence.to_i)
        @previous_controller,@previous_action,@previous_id = "es_contents","list",nil
      when "EsContent"
        element=EsContent.find(@element_id)
        @element_name = "contenu %{name}".trn(:name => element.name)
        @previous_controller,@previous_action,@previous_id = "es_contents","list",nil
    end
    return element
  end

  def create_conditions

    conditions = ["es_content_id is not null"]

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += "(UPPER(es_contents.name) LIKE UPPER(?))"
      conditions << "%#{params[:global_search]}%"
    end


    return conditions
    
  end

end
