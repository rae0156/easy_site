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
  
  def refresh_file
    EsTemplate.load_template_file
    flash[:notice] = "Les templates par fichier ont été rafraichis.".trn
    redirect_to :action => :list
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
        flash[:message_ajax] = "Les parties du template '%{name}' ont été correctement sauvées.".trn(:name => @template.name) 
        @element_id, @partial = 'message_ajax', 'layouts/part_message_ajax'
        render 'shared/replace_content'
      end
    end
  end
  
  def update_design_wizard_parts
    id = params[:id]
    @template = EsTemplate.find_by_id(id)
    @template.save_design(params[:parts]) if params[:parts].present?
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        flash[:message_ajax] = "Les parties du template '%{name}' ont été correctement sauvées.".trn(:name => @template.name) 
        @element_id, @partial = 'div_wizard','es_templates/form_design_wizard'
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
    
    if @part.is_dynamic
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

  def new_content
    id = params[:id]
    @part = EsPart.find_by_id(id)
    @template =     @part.es_template
    @name_list = EsPart.get_name_list(['content'])
  end

  def create_content
    id = params[:id]
    @part = EsPart.find_by_id(id)
    @template =     @part.es_template
    @name_list = EsPart.get_name_list(['content'])
    @part.num = 0
    
    if @part.is_dynamic
      content = EsContent.find_by_name(params[:dummy][:content_name])
      @part.es_content_id = content.id if content
    end
    
    if @part.save
      flash[:notice] = "Le contenu a été lié à la partie '%{name}'.".trn(:name => @part.name)
      redirect_to :action => :parts, :id => @template.id
    else
      render :action  => 'new_content'
    end
  end
  
  def detach_content
    id = params[:id]
    @part = EsPart.find_by_id(id)
    @template =     @part.es_template
    @part.update_attribute('es_content_id', nil)
    flash[:notice] = "Le contenu a été correctement détaché de la partie '%{name}'.".trn(:name => @part.name)
    redirect_to :action => :parts, :id => @template.id
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
  
  def refresh_design
    @template = EsTemplate.find_by_id(params[:id])
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def add_free_elem
    id_col = params[:id]
    es_col = EsTemplateCol.find_by_id(id_col)
    @template = es_col.es_template_line.es_template

    description = "Texte libre".trn + " #{Time.zone.now.strftime("%d%m%Y_%H%M%S")}"
    name = description.gsub(' ', '_').downcase
    content = EsContent.new(:name => name)
    content.save
    content.es_content_details << EsContentDetail.new(:sequence => 1, :content => "<p>Ceci est un texte libre</p>", :editable => "Y", :content_type => "free")

    parts = es_col.es_parts.order("num")
    num = (parts.empty? ? 0 : parts.last.num) + 1
    es_col.es_parts << EsPart.new(:name => name, :description => description, :es_template_id => @template.id, :es_content_id => content.id, :num => num)
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def add_module_elem
    id_col = params[:id]
    @template_col = EsTemplateCol.find_by_id(id_col)
    @template = @template_col.es_template_line.es_template
    @mode = "module"

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  

  def save_part_elem
    id_col = params[:id]
    @template_col = EsTemplateCol.find_by_id(id_col)
    @template = @template_col.es_template_line.es_template

    part = params[:part].presence
    if part.blank? || part[:name].blank?
      @mode = "part_file"
      @part = EsPart.new
      @name_list = EsPart.get_name_list(['part'])
      flash[:error_message_ajax] = "Une partie doit être choisie".trn 
    else
      parts = @template_col.es_parts.order("num")
      num = (parts.empty? ? 0 : parts.last.num) + 1
      part[:description] = part[:name] if part[:description].presence.blank?
      new_part = EsPart.new(:name => part[:name], :description => part[:description], :es_template_id => @template.id, :num => num)
      if new_part.valid?
        @template_col.es_parts << new_part
      else
        @mode = "part_file"
        @part = new_part
        @name_list = EsPart.get_name_list(['part'])
      end
         
    end

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def save_module_elem
    id_col = params[:id]
    @template_col = EsTemplateCol.find_by_id(id_col)
    @template = @template_col.es_template_line.es_template

    module_action_name =  (params[:content].present? && params[:content][:module_action_name].present?) ? params[:content][:module_action_name].presence : nil
    if module_action_name.blank?
      @mode = "module"
      flash[:error_message_ajax] = "L'action d'un module doit être choisi".trn 
    else
      description = "Module".trn + " #{module_action_name}" + " #{Time.zone.now.strftime("%d%m%Y %H%M%S")}"
      name = description.gsub(' ', '_').downcase
      content = EsContent.new(:name => name)
      content.save
      detail = EsContentDetail.new(:sequence => 1, :es_content_id => content.id, :content => "", :editable => "N", :content_type => "module", :module_action_name => module_action_name)
      detail.save
      module_action_name_array = module_action_name.split(' ')
      #detail.update_attribute("content", "<%= generate_module_part('#{module_action_name_array[0]}','#{module_action_name_array[1]}',#{detail.id})%>")
      detail.create_module_params(EsModule.get_module_params(module_action_name_array[0],module_action_name_array[1]))  
  
      parts = @template_col.es_parts.order("num")
      num = (parts.empty? ? 0 : parts.last.num) + 1
      @template_col.es_parts << EsPart.new(:name => name, :description => description, :es_template_id => @template.id, :es_content_id => content.id, :num => num)
    end

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def update_module_elem
    @template = EsTemplate.find_by_id(params[:template_id])
     
    contentdetail = EsContentDetail.find(params[:id])
    contentdetail.save_module_params(params[:generated]) if params[:generated].present?
    flash[:message_ajax] = "La partie '%{name}' a été correctement sauvée.".trn(:name => contentdetail.name) 
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end    
  end
  
  def add_part_file_elem
    id_col = params[:id]
    @template_col = EsTemplateCol.find_by_id(id_col)
    @template = @template_col.es_template_line.es_template
    @mode = "part_file"
    @part = EsPart.new
    @name_list = EsPart.get_name_list(['part'])

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def add_dynamic_elem
    id_col = params[:id]
    es_col = EsTemplateCol.find_by_id(id_col)
    @template = es_col.es_template_line.es_template

    description = "Element dynamique".trn + " #{Time.zone.now.strftime("%d%m%Y_%H%M%S")}"
    name = description.gsub(' ', '_').downcase
    content = EsContent.new(:name => name)
    content.save
    detail = EsContentDetail.new(:sequence => 1, :es_content_id => content.id, :content => "", :editable => "Y", :content_type => "dynamic")
    detail.save
    detail.update_attribute("content", "<%= generate_dynamic_part(#{detail.id})%>")

    parts = es_col.es_parts.order("num")
    num = (parts.empty? ? 0 : parts.last.num) + 1
    es_col.es_parts << EsPart.new(:name => name, :description => description, :es_template_id => @template.id, :es_content_id => content.id, :num => num)
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def delete_part
    sub_action = params[:sub_action]||'detach'
    id_part = params[:id]
    part = EsPart.find_by_id(id_part)

    @template = part.es_template

    content = part.es_content
    
    if sub_action=="destroy"
      if !(content.blank?) && content.es_parts.size == 1
        content.es_content_details.each do |dtl|
          dtl.es_content_detail_params.destroy_all
          dtl.es_content_detail_elements.destroy_all
        end
        content.es_content_details.destroy_all   
        content.destroy   
      end
      part.destroy
    else
      part.update_attributes(:es_template_col_id=>nil, :num => nil)
    end
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end

  def save_rename_part

    id = params[:id]
    @part = EsPart.find_by_id(id)
    @template = @part.es_template
    
    if @part.update_attributes(params[:part])
      flash[:message_ajax] = "La partie '%{name}' a été correctement modifiée.".trn(:name => @part.name) 
    else
      @mode = "rename"
    end
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end

  def rename_part
    id_part = params[:id]
    @part = EsPart.find_by_id(id_part)
    @template = @part.es_template
    @mode = "rename"
      
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def edit_part
    id_part = params[:id]
    @part = EsPart.find_by_id(id_part)

    @mode = "edit_not_possible"
    @template = @part.es_template
    if @part.is_dynamic && !@part.es_content.blank?
      content_detail = @part.es_content.es_content_details.first
      case content_detail.content_type
        when "free"
          @content_detail_id  = content_detail.id
          @content_tiny       = content_detail.content
          @mode = "edit_free"
        when "module"
          @contentdetail      = content_detail
          @mode = "edit_module"
        when "dynamic"
          session[:dynamic_content_view_normal]=false
          @content_detail_id = content_detail.id
          @content_detail = content_detail
          @mode = "edit_dynamic"
      end
    end
      
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def preview_template
    id_template = params[:id]
    @template = EsTemplate.find_by_id(id_template)

    session[:parts_preview] = @template.es_part_ids    
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def not_preview_template
    id_template = params[:id]
    @template = EsTemplate.find_by_id(id_template)

    session[:parts_preview] = []    
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end

  def preview_column
    id_col = params[:id]
    es_col = EsTemplateCol.find_by_id(id_col)
    @template = es_col.es_template_line.es_template

    session[:parts_preview] += es_col.es_part_ids    
    session[:parts_preview].uniq!
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def not_preview_column
    id_col = params[:id]
    es_col = EsTemplateCol.find_by_id(id_col)
    @template = es_col.es_template_line.es_template

    session[:parts_preview] -= es_col.es_part_ids    
    session[:parts_preview].uniq!
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end

  def preview_part
    es_part = EsPart.find_by_id(params[:id])
    @template = es_part.es_template
    
    session[:parts_preview] << (params[:id]||0).to_i
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
  end
  
  def not_preview_part
    es_part = EsPart.find_by_id(params[:id])
    @template = es_part.es_template
    
    session[:parts_preview].delete((params[:id]||0).to_i)
    
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'div_wizard', 'es_templates/form_design_wizard'
        render 'shared/replace_content'
      end
    end
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
