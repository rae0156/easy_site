# encoding: UTF-8

class EsTemplatesController < ApplicationController
  def list
    sorting :default => 'name'
    session[:conditions_template] = create_conditions
    @templates = EsTemplate.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_template]

    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'template_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  def new
    @categories = EsCategory.get_categories('template')
    @template = EsTemplate.new
  end
  
  def create
    @categories = EsCategory.get_categories('template')
    @template = EsTemplate.new(params[:template])

    if @template.save
      flash[:notice] = "Le template '%{name}' a été créé.".trn(:name => @template.name)
      redirect_to :action => :list
    else
      render :action  => 'new'
    end
  end
  
  def edit
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @categories = EsCategory.get_categories('template')
  end

  def update
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @categories = EsCategory.get_categories('template')
    
    if @template.update_attributes(params[:template])
      flash[:notice] = "Le template '%{name}' a été correctement modifié.".trn(:name => @template.name)
      redirect_to :action => :list
    else
      render :action => 'edit'
    end
  end
  
  def validation
    id = params[:id]
    template = EsTemplate.find_by_id(id)
    template.validated = template.validated == "Y" ? "N" : "Y"
    template.save
    
    redirect_to :action => :list
  end
  
  def line_up
    id = params[:id]
    template_line = EsTemplateLine.find_by_id(id)
    template_line.update_attribute('num',template_line.num - 1.5)
    template_line.es_template.compress_line
    redirect_to :action => "design", :id => template_line.es_template.id 
  end
  
  def line_down
    id = params[:id]
    template_line = EsTemplateLine.find_by_id(id)
    template_line.update_attribute('num',template_line.num + 1.5)
    template_line.es_template.compress_line
    redirect_to :action => "design", :id => template_line.es_template.id 
  end
  
  def design
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @template_lines = @template.es_template_lines
    @template_line_value = params[:template_line]||{}

  end
  
    
  def destroy_line
    tmp_element_error = EsTemplate.new
    tmp = EsTemplateLine.find(params[:id])
    template = tmp.es_template
    if tmp.destroy
      template.compress_line
    else
      tmp.errors.full_messages.each do |tmp_error| 
        tmp_element_error.errors.add(:base, "Ligne du template '%{name}' : %{error}.".trn(:name => template.name, :error => tmp_error))
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "La ligne du template '%{name}' a correctement été supprimée.".trn(:name => template.name)
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "design", :id => template.id 
  end


  def add_line
    tmp_element_error = EsTemplate.new
    template = EsTemplate.find(params[:id])

    unless template.add_line(params[:template_line])
      template.errors.full_messages.each do |tmp_error| 
        tmp_element_error.errors.add(:base, "Ligne du template '%{name}' : %{error}.".trn(:name => template.name, :error => tmp_error))
      end
    end    

    if tmp_element_error.errors.empty? 
      flash[:notice] = "Une ligne a correctement été ajoutée au template '%{name}'.".trn(:name => template.name)
    else
      flash[:errors_add] = tmp_element_error
    end
    redirect_to :action => "design", :id => template.id , :template_line => params[:template_line]

  end

  def destroy
    tmp_element_error = EsTemplate.new
    tmp = EsTemplate.find(params[:id])
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "Template '%{name}' : %{error}.".trn(:name => tmp.name, :error => tmp_error))
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "Le template '%{name}' a correctement été supprimé.".trn(:name => name)
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  def export_csv
    templates = EsTemplate.find :all, :conditions => session[:conditions_template]
    file_name = "templates_export.csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Nom".trn,"Description".trn,"Catégorie".trn]
       templates.each do |t|
          csv << [t.name,t.description,t.es_category.blank? ? "" : t.es_category.name]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end


  def design_parts
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
  end
  
  def update_design_parts
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @template.save_design(params[:parts]) if params[:parts].present?
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        flash[:message_ajax] = "Les parties du template '%{name}' ont été correctement assignées.".trn(:name => @template.name) 
        @element_id, @partial = 'message_ajax', 'layouts/part_message_ajax'
        render 'shared/replace_content'
      end
    end


  end
  
  
  
  
  def parts
    sorting :default => 'name'
    session[:conditions_template_part] = create_conditions("es_parts")

    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @template_parts = @template.es_parts.all(:order => @sort, :conditions => session[:conditions_template_part])

    respond_to do |format|
      format.html {}
      format.js do 
        @element_id, @partial = 'template_part_div', 'list_part'
        render 'shared/replace_content'
      end
    end
  end
  
  def new_part
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @part = EsPart.new
    @name_list = EsPart.get_name_list
  end
  
  def create_part
    @template = EsTemplate.find_by_id(params[:template_id])
    @name_list = EsPart.get_name_list

    @part = EsPart.new(params[:part])
    @part.es_template_id = params[:template_id]
    @part.num = 0
    
    unless @part.name.starts_with?("part_")
      content = EsContent.find_by_name(@part.name)
      @part.es_content_id = content.id if content
    end
    
    if @part.save
      flash[:notice] = "La partie '%{name}' a été créée.".trn(:name => @part.name)
      redirect_to :action => :parts, :id => params[:template_id]
    else
      render :action  => 'new_part'
    end
  end
  
  def destroy_part
    tmp_element_error = EsPart.new
    tmp = EsPart.find(params[:id])
    template_id = tmp.es_template_id
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "Partie '%{name}' : %{error}.".trn(:name => tmp.name, :error => tmp_error))
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "La partie '%{name}' a correctement été supprimée.".trn(:name => name)
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "parts", :id => template_id
  end

  def edit_part
    id = params[:id]
    @part = EsPart.find_by_id(id)
    @template = @part.es_template
    @name_list = EsPart.get_name_list
  end

  def update_part
    id = params[:id]
    @part = EsPart.find_by_id(id)
    @template = @part.es_template
    @name_list = EsPart.get_name_list
    
    if @part.update_attributes(params[:part])
      flash[:notice] = "La partie '%{name}' a été correctement modifiée.".trn(:name => @part.name)
      redirect_to :action => "parts", :id => @template.id
    else
      render :action => 'edit_part'
    end
  end
  
  def design_content
    id_part = params[:id]
    part = EsPart.find(id_part)
    redirect_to :controller => "tinymce", :action => "config_content", :from_template => true, :ajax_param=> {:selection =>{"es_template_id"=>"#{part.es_template_id}", "es_part_id"=>"#{id_part}", "es_content_detail_id"=>""}}
  end
  
  
private


  def create_conditions(table="es_templates")

    conditions = []

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += "(UPPER(#{table}.name) LIKE UPPER(?))"
      conditions << "%#{params[:global_search]}%"
    end


    return conditions
    
  end
   
end
