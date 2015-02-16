# encoding: UTF-8

class DynamicController < ApplicationController
  include PDFHelper

  
  before_filter :init_parent_id_for_bad_model
  before_filter :init_model_level

  before_filter :init_back, :only => ["list","index"]
  before_filter :get_by_id, :only => ["edit", "update", "destroy","down","up","activate"]
  before_filter :clean_msg, :only => ["edit", "update", "destroy"]

  def initialize()

    #self.class.load_and_authorize_resource
    self.class.before_filter :login_required 
    
    
    @controller_link_to                  ||= {}
    @setup_controller                    ||= {}
    @setup_controller[:controller_name]  ||= controller_name
    @setup_controller[:model]            ||= controller_name.classify.constantize
    @setup_controller[:instance_name]    ||= @setup_controller[:model].table_name.gsub("es_","").humanize.singularize
    @setup_controller[:model_level]      ||= []
    @setup_controller[:max_level]        ||= 9999
     

    @setup_controller[:model].setup_model.each do |key,value|
      @setup_controller[key] = value 
    end unless @setup_controller[:model].setup_model.blank?     

    column_setup = @setup_controller[:model].columns_setup
    columns_screen_forced = @columns_screen||[]
    field_defined_model_or_ctrl = []
    @columns_screen = []
    @setup_controller[:model].columns.each do |column|
      tmp_columns_screen = init_default_columns_screen(column)
      

#      get attribute from model
      exist_column_setup = column_setup.select{|col| col[:name]==column.name}
      field_defined_model_or_ctrl << column.name unless exist_column_setup.blank?
      exist_column_setup = exist_column_setup.blank? ? {} : exist_column_setup[0]
      exist_column_setup.each do |key,value|
        tmp_columns_screen[key] = value.nil? ? tmp_columns_screen[key] : value 
      end unless exist_column_setup.blank?     
               
#      merge forced attribute
      new_columns_screen = {}
      exist_columns_screen = columns_screen_forced.select{|col| col[:name]==column.name}
      field_defined_model_or_ctrl << column.name unless exist_columns_screen.blank?
      exist_columns_screen = exist_columns_screen.blank? ? {} : exist_columns_screen[0]
      columns_screen_forced.delete_if{ |col| col[:name]==column.name}
      tmp_columns_screen.each do |key,value|
        new_columns_screen[key] = exist_columns_screen[key].nil? ? value : exist_columns_screen[key] 
      end      
      
      new_columns_screen[:hidden] = true if @setup_controller[:only_field_defined] && !field_defined_model_or_ctrl.include?(column.name)
      @columns_screen << new_columns_screen                          

    end

    #insert column added into the model with no field in the table
    #insert column added into the controller with no field in the table
    manage_field_out_of_table(column_setup,columns_screen_forced)

    #remove hide column
    @columns_screen.select! { |hsh| (hsh[:hidden]||false)==false } 
    
    #manage order of column to display
    manage_order_setup_to_display
       

    @setup_controller[:mandatory_exists]       ||= @columns_screen.select{ |col| col[:mandatory]}.count > 0
    @setup_controller[:dynamic_filter_exists]    = @setup_controller[:dynamic_filter_exists].nil? ? @columns_screen.select{ |col| col[:dynamic_filter]}.count > 0 : @setup_controller[:dynamic_filter_exists]
    @setup_controller[:dynamic_search_exists]    = @setup_controller[:dynamic_search_exists].nil? ? @columns_screen.select{ |col| col[:dynamic_search]}.count > 0 : @setup_controller[:dynamic_search_exists]
    @setup_controller[:parent_exists]            = @setup_controller[:parent_exists].nil? ? @columns_screen.collect{ |col| col[:name]}.include?("parent_id") : @setup_controller[:parent_exists]
    @setup_controller[:sequence_exists]          = @setup_controller[:sequence_exists].nil? ? @columns_screen.collect{ |col| col[:name]}.include?("sequence") : @setup_controller[:sequence_exists]
    @setup_controller[:category_exists]        ||= @columns_screen.collect{ |col| col[:name]}.include?("es_category_id")
    @setup_controller[:column_name_exists]     ||= @columns_screen.collect{ |col| col[:name]}.include?("name")
    @setup_controller[:default_column_name]    ||= @setup_controller[:column_name_exists] ? "name" : (@columns_screen.collect{ |col| col[:name]}.include?("code") ? "code" : "id")
    @setup_controller[:default_sort]           ||= @setup_controller[:sequence_exists] ? "sequence" : "id"
    @setup_controller[:table_field_active]     ||= @columns_screen.collect{ |col| col[:name]}.include?("active")
    @setup_controller[:delete_if_used]           = @setup_controller[:delete_if_used].nil? ? false : @setup_controller[:delete_if_used] 
    @setup_controller[:delete_if_inactive]       = @setup_controller[:delete_if_inactive].nil? ? false : @setup_controller[:delete_if_inactive] 
    @setup_controller[:delete_multi]             = @setup_controller[:delete_multi].nil? ? false : @setup_controller[:delete_multi] 
    @setup_controller[:readonly_exists]        ||= @columns_screen.collect{ |col| col[:name]}.include?("read_only")
    @setup_controller[:search_exists]            = @setup_controller[:search_exists].nil? ? @columns_screen.select{ |col| col[:search]}.count > 0 : @setup_controller[:search_exists]

    @setup_controller[:children_exists]          = @setup_controller[:children_exists].nil? ? @setup_controller[:parent_exists] : @setup_controller[:children_exists]

    @setup_controller[:search_tab_order]       ||= ['s','d','p']
    @setup_controller[:search_tab_order].delete('s') unless @setup_controller[:search_exists]
    @setup_controller[:search_tab_order].delete('d') unless @setup_controller[:dynamic_search_exists]
    @setup_controller[:search_tab_order].delete('p') unless @setup_controller[:parent_exists]

    @setup_controller[:option_export]            = @setup_controller[:option_export].nil? ? true  : @setup_controller[:option_export] 
    @setup_controller[:option_show]              = @setup_controller[:option_show].nil?   ? false : @setup_controller[:option_show] 


    @setup_controller[:list_options]           ||= [] 
    @setup_controller[:associations]           ||= {} 




    #traduction
    translate_setup
    @controller_link_to.each do |k,v|
      [:title,:description,:title_left,:title_right].each do |attr|
        @controller_link_to[k][attr]        =v[attr].trn unless v[attr].blank?     
      end
    end

    super
  end


  def associate 

    @instance = @setup_controller[:model].find_by_id(params[:id]) 
    
    begin 
      collection_to_associate = params[:model].present? ? (params[:model]).constantize : nil 
    rescue 
      collection_to_associate = nil 
    end    
    
    association = @setup_controller[:associations][params[:model].downcase.to_sym].presence 
    
    if association 
      if collection_to_associate 
        field = (association[:field_to_display].presence || "id") 
        field = 'id' unless collection_to_associate.new.respond_to?(field) 
        @text_to_associate            = association[:text].presence || "..." 
        @list_field                   = (association[:field_list].presence || "").split(",") 
        @associate_field_id           = "#{collection_to_associate.name.underscore}_ids" 
        @list                         = collection_to_associate.all 
        @association_field_to_display = field 
        render "shared/dynamic/associate"  
      else 
        flash[:error] = "Le modèle '%{model}' n'est pas paramétré dans 'list_options' pour le controlleur '%{controller_name}'.".trn(:model => params[:model], :controller_name => @setup_controller[:controller_name])
        redirect_to :action => "list",:page=> params[:page] 
      end 
    else 
      flash[:error] = "L'association '%{association}' n'est pas paramétrée.".trn(:association => params[:model].downcase) 
      redirect_to :action => "list",:page=> params[:page] 
    end 
  end 

  def update_associate 
    @instance = @setup_controller[:model].find_by_id(params[:id]) 
    @instance.update_attributes(params[:instance]) 
    flash[:notice] = "L'élément '%{instance_name}' a été modifié.".trn(:instance_name => @setup_controller[:instance_name].humanize) 
    redirect_to :action => "list",:page=> params[:page] 
  end 



  # Load the pages -
  def list
    
        
    param_dir = params[:dir]||''
    unless param_dir.blank?
      param_dir.end_with?('/') ? params[:parent_id] = param_dir[0...-1].to_i : params[:id] = param_dir    
    end
        
    parent_id= nil   
    if params[:parent_id].presence 
      #sans recherche
      parent_id = params[:parent_id]
      session[:parent_id]=""
    else
      #avec recherche
      parent_id = session[:parent_id]
    end


    ####################################### init info #######################################
    init_info_for_list(parent_id)


    ####################################### tri ####################################### 

    sorting :default => "#{@setup_controller[:model].table_name}.#{@setup_controller[:default_sort]}"
    
    ####################################### condition ####################################### 
    
    tmp_search={}
    if(!params[:global_search].blank?)
      tmp_query=[""]
      @columns_screen.select{|column| column[:search]}.each do |column| 
        tmp_query[0] += (tmp_query[0].blank? ? "" : " OR ") + "(UPPER(#{column[:name]}) LIKE UPPER(?) )"
        tmp_query << "%#{params[:global_search]}%"
      end  
      tmp_search[:global_search]=tmp_query
    elsif !params[:dynamic_search].blank?
      tmp_search = params[:dynamic_search].clone
    elsif !params[:dynamic_filter].blank?
      tmp_search = params[:dynamic_filter].clone
    end

    session.delete(:parent_id) 
    if @setup_controller[:parent_exists]
      unless params[:id].blank?
        tmp_search[:id]=params[:id]
      end
      if parent_id.blank?
        tmp_search[:parent_id]=0
      else
        tmp_search[:parent_id]=parent_id
      end
      #ne pas mettre en commentaire, car les filtres et recherches ne fonctionnent plus
      session[:parent_id] = parent_id unless parent_id.blank?
    end

    tmp_search.merge! @setup_controller[:fixed_attributes] if @setup_controller[:fixed_attributes]

    conditions = DynamicSearch.new(@setup_controller[:model],tmp_search).build_conditions #.accessible_by(current_ability)

      

    ####################################### pagination ####################################### 

    session[:conditions] = tmp_search
    session[:sort] = @sort
#    @instances = @setup_controller[:model].paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => conditions
    @instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).page(params[:page])


    ####################################### retour ####################################### 
#    @element_id, @partial = 'dynamic_list_div', 'shared/dynamic/list'
#    render 'shared/replace_content', :formats => [:js]

    respond_to do |format|
      format.html {render "shared/dynamic/list"} 
      format.js do 
        @element_id, @partial = 'dynamic_list_div', 'shared/dynamic/list'
        render 'shared/replace_content'
      end
    end
  end

  alias index list

  def show
      @instance = @setup_controller[:model].find_by_id(params[:id])
  
      render "shared/dynamic/show"
  end


  def show_setup
    
    tmp_text = "<H1>Controller '<a href=""#{'list'}"">#{@setup_controller[:controller_name]}</a>'</H1>" 
    tmp_text += "<H2>Setup :</H2>" 
    @setup_controller.sort.each do |k,v|
      tmp_text += "#{k} : #{v}<BR>"
    end
    tmp_text += "<H2>Column screen setup :</H2>" 
    @columns_screen.each do |elem|
      tmp_text += "<H3>#{elem[:name]} : </H3>"
      elem.sort.each do |k,v| 
        tmp_text += "#{k} : #{v}<BR>"
      end
    end
    tmp_text+="<BR>"
    @text_setup = tmp_text.html_safe
    render 'shared/dynamic/show_setup'
  end

  #move down
  def down
    order = @instance.sequence
    element = @setup_controller[:model].find(:first, :conditions => ["parent_id = ? and sequence=?","#{@instance.parent_id}",@instance.sequence + 1])
    unless element.blank?
      element.update_attribute("sequence",order) 
      @instance.update_attribute("sequence",order + 1) 
    end

    respond_to do |format|
      format.html {redirect_to :action => "list", :parent_id => @instance.parent_id} 
      format.js do 
        init_info_for_list(session[:parent_id])
        conditions = DynamicSearch.new(@setup_controller[:model],session[:conditions]).build_conditions
        @instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).page(params[:page])
        @element_id, @partial = 'dynamic_list_div', 'shared/dynamic/list'
        render 'shared/replace_content'
      end
    end
    
  end

  #move up
  def up
    order = @instance.sequence
    element = @setup_controller[:model].find(:first, :conditions => ["parent_id = ? and sequence=?","#{@instance.parent_id}",@instance.sequence - 1])
    unless element.blank?
      element.update_attribute("sequence",order) 
      @instance.update_attribute("sequence",order - 1) 
    end

    respond_to do |format|
      format.html {redirect_to :action => "list", :parent_id => @instance.parent_id} 
      format.js do 
        init_info_for_list(session[:parent_id])
        conditions = DynamicSearch.new(@setup_controller[:model],session[:conditions]).build_conditions
        @instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).page(params[:page])
        @element_id, @partial = 'dynamic_list_div', 'shared/dynamic/list'
        render 'shared/replace_content'
      end
    end

  end


  
  #Create an empty new in order to be used in the new new screen -
  def new
    @instance = @setup_controller[:model].new()
    @parent = @setup_controller[:parent_exists] && params[:parent_id] && params[:parent_id].to_i > 0 ? @setup_controller[:model].find_by_id(params[:parent_id]) : nil 
    @back_to_parent = (@parent.blank? || @parent.ancestors.count == 0 ? "" : (@parent.children.count == 0 ? @parent.ancestors[0].id : @parent.id))
    render "shared/dynamic/new"
  end
   
  # Save the New to database -
  def create
    params[:instance][:sequence]  = 999999999 if @setup_controller[:sequence_exists]
    params[:instance][:parent_id] = 0         if @setup_controller[:parent_exists] && params[:instance][:parent_id].blank?
    params[:instance].merge! @setup_controller[:fixed_attributes] if @setup_controller[:fixed_attributes]

    transform_list(params[:instance])
    
    @instance = @setup_controller[:model].new(params[:instance])
    if @instance.save

      initial_sequence_for(@setup_controller[:parent_exists] ? @instance.parent_id : '') if @setup_controller[:sequence_exists]

      flash[:notice] = "'%{element_dynamique}' créé avec succès.".trn(:element_dynamique => @setup_controller[:instance_name])

      if @setup_controller[:parent_exists]
        redirect_to :action => "list", :parent_id => params[:instance][:parent_id]
      else
        redirect_to :action => "list"
      end
    else
      params[:action]="new"
      @parent = @setup_controller[:parent_exists] && params[:instance][:parent_id] && params[:instance][:parent_id].to_i > 0 ? @setup_controller[:model].find_by_id(params[:instance][:parent_id]) : nil 
      @back_to_parent = (@parent.blank? || @parent.ancestors.count == 0 ? "" : (@parent.children.count == 0 ? @parent.ancestors[0].id : @parent.id))
      render "shared/dynamic/new"
    end
  end
  
  def edit
    render "shared/dynamic/edit"
  end
  
  def update
    transform_list(params[:instance])
    if @instance.update_attributes(params[:instance])
      flash[:notice] = "'%{element_dynamique}' a été correctement modifié".trn(:element_dynamique => @setup_controller[:instance_name]) +"."
      if @setup_controller[:parent_exists]
        redirect_to :action => "list", :parent_id => params[:instance][:parent_id]
      else
        redirect_to :action => "list"
      end
    else
      params[:action]="edit"
      render "shared/dynamic/edit"
    end
  end
  
  
  def activate

    if @instance.active=='N'
      @instance.update_attribute('active','Y')    
      flash[:notice] = "%{element_dynamique} a été activé.".trn(:element_dynamique=> @setup_controller[:instance_name])
      redirect_to :action => "list",:page=> params[:page]
    else
      destroy = !detect_association(@instance,['audits']).blank? ? @setup_controller[:delete_if_used] : @setup_controller[:delete_if_inactive]
      unless destroy 
        @instance.update_attribute('active',@instance.active=='Y' ? 'N' : 'Y')    
        flash[:notice] = "%{element_dynamique} a été #{@instance.active=='Y' ? 'activé' : 'désactivé'}.".trn(:element_dynamique=> @setup_controller[:instance_name])
        redirect_to :action => "list",:page=> params[:page]
      else
        redirect_to :action => "destroy",:id=> params[:id]      
      end
    end
  end  
  
  def destroy

    tmp_element_error = @setup_controller[:model].new
    for id in params[:cid]
      tmp = @setup_controller[:model].find(id)
      back_to_parent = @setup_controller[:parent_exists] && tmp.ancestors.count > 0 ? (tmp.ancestors[0].children.count > 1 ? tmp.parent_id : tmp.ancestors[0].parent_id) : ""      
      
      if @setup_controller[:readonly_exists] && tmp["read_only"]=='Y'
        tmp_element_error.errors.add(:base, "La suppresison de '%{element_dynamique}' ne peut être faite, cet élément est en lecture seule.".trn(:element_dynamique => @setup_controller[:model_name].singularize))
      elsif !@setup_controller[:delete_if_used] && !detect_association(@instance,['audits']).blank?
        tmp_element_error.errors.add(:base, "La suppresison de '%{element_dynamique}' ne peut être faite, car une ou plusieurs liaisons existent.".trn(:element_dynamique => @setup_controller[:model_name].singularize))
      elsif check_children_before_delete(tmp) || !tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "'#{@setup_controller[:instance_name]} - #{tmp.name}' : #{tmp_error}")
        end
      else
        initial_sequence_for(@setup_controller[:parent_exists] ? tmp.parent_id : '') if @setup_controller[:sequence_exists]
      end
    end unless params[:cid].blank?
    
    unless params[:id].blank?
      @instance = @setup_controller[:model].find_by_id(params[:id])
      detect = detect_association(@instance,['audits'])
      if detect.blank? || @setup_controller[:delete_if_used]
        tmp_parent_id = @setup_controller[:parent_exists] ? @instance.parent_id : ''
        @instance.destroy unless @instance.blank?
        initial_sequence_for(tmp_parent_id) if @setup_controller[:sequence_exists]
      else
        tmp_element_error.errors.add(:base, "La suppresison de '%{element_dynamique}' ne peut être faite, car une ou plusieurs liaisons existent".trn(:element_dynamique => @setup_controller[:instance_name].humanize) + ". (#{detect.join(', ')})")
      end
    end    
    
    if tmp_element_error.errors.empty? 
      flash[:notice] = "'%{element_dynamique}' correctement supprimé(s).".trn(:element_dynamique => @setup_controller[:instance_name]) 
    else
      flash[:errors_destroy] = tmp_element_error
    end


    respond_to do |format|
      format.html do
        if @setup_controller[:parent_exists]
          redirect_to :action => "list", :parent_id => back_to_parent
        else
          redirect_to :action => "list"
        end
      end         
      format.js do 
        init_info_for_list(session[:parent_id])
        conditions = DynamicSearch.new(@setup_controller[:model],session[:conditions]).build_conditions
        @instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).page(params[:page])
        @element_id, @partial = 'dynamic_list_div', 'shared/dynamic/list'
        render 'shared/replace_content'
      end
    end


  end

  def export_pdf_dyn

    file_name = "rapport_pdf_#{@setup_controller[:model].table_name}_#{Time.zone.now.strftime("%Y%m%d%H%M%S%L")}.pdf"
    pdf = Prawn::Document.new

    #Create the first page
    create_title_page(pdf, "Liste".trn + " - #{@setup_controller[:instance_name]}","Date et Heure".trn + " : #{Time.zone.now.strftime("%d/%m/%Y %H:%M:%S")}" ) 
    
    pdf.start_new_page()
    pdf.font_size 12
    
    # Find all New with the stored restrictions
    conditions = DynamicSearch.new(@setup_controller[:model],session[:conditions]).build_conditions.accessible_by(current_ability)
    instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).find :all
    data = []

      tab_header=[]
      @columns_screen.each do |column|
        tab_header << column[:label_name] if column[:print]
      end
      data << tab_header

      instances.each do |t|
        tab_line=[]
        @columns_screen.each do |column|
          if column[:print]
            tmp_value = t.multi_send(column[:name]) 
            if column[:foreign]
              unless tmp_value.blank?
                tmp_model_link = t.send(column[:name][0..-4])
                tmp_value = tmp_model_link.class.column_names.include?("name") ? tmp_model_link.name : tmp_model_link.id
              end
            end
            if !tmp_value.blank?
              if column[:type]== "datetime"
                tmp_value = tmp_value.strftime("%d/%m/%Y %H:%M:%S") if !tmp_value.blank? && ["datetime","date","time"].include?(column[:type])
              elsif column[:type]== "date"
                tmp_value = tmp_value.strftime("%d/%m/%Y")
              elsif column[:type]== "time"
                tmp_value = tmp_value.strftime("%H:%M:%S")
              end
            end
            tab_line << (tmp_value || "")
          end

        end
        data << tab_line
      end
    
    pdf.font_size 8
    pdf.table(data    , :row_colors => ["FFFFFF", "EAEAEA"], :header => true) do |table|
      table.row(0).font_style = :bold
    end unless data.blank?
    
    
    dir="public/files"
    create_dir(dir)
    pdf.render_file File.join(dir,file_name)
    #Send the PDF report to the browser
    download_pdf(pdf, file_name)
    
  end

  def export_csv_dyn
    # Find all New with the stored restrictions
    conditions = DynamicSearch.new(@setup_controller[:model],session[:conditions]).build_conditions.accessible_by(current_ability)
    instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).find :all
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|

      tab_header=[]
      @columns_screen.each do |column|
        tab_header << column[:label_name] if column[:print]
      end
      csv << tab_header


      instances.each do |t|
        tab_line=[]
        @columns_screen.each do |column|
          if column[:print]
            
            tmp_value = t.multi_send(column[:name]) 
            if column[:foreign]
              unless tmp_value.blank?
                tmp_model_link = t.send(column[:name][0..-4])
                tmp_value = tmp_model_link.class.column_names.include?("name") ? tmp_model_link.name : tmp_model_link.id
              end
            end
            if !tmp_value.blank?
              if column[:type]== "datetime"
                tmp_value = tmp_value.strftime("%d/%m/%Y %H:%M:%S") if !tmp_value.blank? && ["datetime","date","time"].include?(column[:type])
              elsif column[:type]== "date"
                tmp_value = tmp_value.strftime("%d/%m/%Y")
              elsif column[:type]== "time"
                tmp_value = tmp_value.strftime("%H:%M:%S")
              end
            end
            tab_line << (tmp_value || "")
          end

        end
        csv << tab_line
      end




    end
    # Creation of the file
    file_name = "#{@setup_controller[:model].model_name.underscore}_export_#{Date.today.strftime("%Y-%m-%d %H:%M:%S")}" + ".csv"
    download_csv(csv_string, file_name)

  end
  


  def contenttree
    param_dir = params[:dir]||''

    parent_id = ""
    parent_id = param_dir.end_with?('/') ? param_dir[0...-1] : param_dir unless param_dir.blank?

    if parent_id.blank?
      conditions = ["(#{@setup_controller[:model].table_name}.parent_id IS NULL OR #{@setup_controller[:model].table_name}.parent_id = 0)"]
    else
      conditions = ["(#{@setup_controller[:model].table_name}.parent_id = ?)","#{parent_id}"]
    end
    
    unless @setup_controller[:fixed_attributes_tree].blank?
      @setup_controller[:fixed_attributes_tree].each do |k,v|
        if v.is_a?(Array)
          conditions[0]+= " AND (#{@setup_controller[:model].table_name}.#{k} IN (?))"
        else
          conditions[0]+= " AND (#{@setup_controller[:model].table_name}.#{k} = ?)"
        end
        conditions   << v
      end
    end
      
    
    instances = @setup_controller[:model].find :all, :order => @setup_controller[:default_sort], :conditions => conditions
    
    tmp_parent=[]
    tmp_child=[]
    instances.each do |elem|
      if elem.children.count > 0
        tmp_parent << [elem.id,elem.name]
      else
        tmp_child << [elem.id,elem.name]
      end               
    end
    @trees = [tmp_parent,tmp_child]
    
    render 'shared/dynamic/contenttree',:layout => false
  end
  
  

  def link_to
    @model_link = params[:id].presence.blank? ? nil : @setup_controller[:model].find_by_id(params[:id])
    @link_to = init_link_to(params[:link])
    @instances = @setup_controller[:model].where(@link_to[:query]).page(params[:page])
    @instances_to_link = @link_to[:model_linked].where(@link_to[:query_link]).page(params[:page])
    @enabled_ids = @setup_controller[:model].where(@link_to[:query_enabled_ids]).collect(&:id)
    link_id_string = get_link_id_field_name(params[:link]) 
    @model_linked_list_ids = @model_link.blank? ? nil : @model_link.send(link_id_string)
    render "shared/dynamic/link_to" 
  end

  def link_to_model
    element = @setup_controller[:model].find_by_id(params[:id])
    link_id_string = get_link_id_field_name(params[:link]) 
    if element && element.respond_to?(link_id_string) && params[:model_linked].present? && params[:model_linked][:id].present? 
      if params[:model_linked][:id].is_a?(Array)
        element.update_attribute(link_id_string,params[:model_linked][:id].reject! { |e| e.empty? }.map{|e| e.to_i})
      else
        element.update_attribute(link_id_string,params[:model_linked][:id].to_i)
      end
    end
    link_to
  end


private

  def init_parent_id_for_bad_model
    #si on change de sorte de liste avec parent/enfant, on réinitialise le parent_id à vide si on ne trouve rien comme enfants
    params[:parent_id] = 0 if @setup_controller[:parent_exists] && @setup_controller[:model].column_names.include?('model_type') && !@setup_controller[:model_level].empty? && @setup_controller[:model_level][0] != get_old_ancestor(params[:parent_id].presence||session[:parent_id].presence||0).model_type
  end
    

  def init_model_level
    @current_level_model=[]
    @current_level=0
    if @setup_controller[:parent_exists]
      case params[:action]
      when "edit"
        if @setup_controller[:model].column_names.include?('model_type') 
          instance = @setup_controller[:model].find_by_id(params[:id])
          begin 
            tmp_model = instance['model_type'].constantize
          rescue 
            tmp_model = nil 
          end    
          init_setup_model_level(tmp_model) if !tmp_model.nil?
        end
      when "new"
        if @setup_controller[:model].column_names.include?('model_type') && params[:model_type].present?
          begin 
            tmp_model = params[:model_type].constantize
          rescue 
            tmp_model = nil 
          end    
          init_setup_model_level(tmp_model) if !tmp_model.nil?
        end
      when "create","update"
        if @setup_controller[:model].column_names.include?('model_type') && params[:instance].present? && params[:instance][:model_type].present?
          begin 
            tmp_model = params[:instance][:model_type].constantize
          rescue 
            tmp_model = nil 
          end    
          init_setup_model_level(tmp_model) if !tmp_model.nil?
        end
      else  
        level=0
        dir = params[:dir] 
        id = params[:id] 
        parent_id = params[:parent_id]||session[:parent_id]
        if dir==''
          level = 1    
        elsif !dir.blank?
          if dir.ends_with?('/')
            level = @setup_controller[:model].find_by_id(dir[0..-2]).get_level + 1
          else
            level = @setup_controller[:model].find_by_id(dir).get_level
          end
        elsif !id.blank?
          level = @setup_controller[:model].find_by_id(id).get_level
        elsif !parent_id.blank?  
          unless parent_id.to_s == "0"
            level = @setup_controller[:model].find_by_id(parent_id).get_level  
          end
          level+=1
        end
        @current_level = level
  
        if level > 0  && !@setup_controller[:model_level].blank?
          model_name = level>@setup_controller[:model_level].size ? @setup_controller[:model_level].last : @setup_controller[:model_level][level - 1] 
          
          model_name = [model_name.to_s] unless model_name.is_a?(Array) and model_name.size > 0
        
          model_name.each do |name|
            begin 
              @current_level_model << name.constantize
            rescue 
              @current_level_model <<  nil 
            end    
          end
  
          unless @current_level_model[0].nil?
            init_setup_model_level(@current_level_model[0])
          end
        end
        
      end

    end
  end


  def init_setup_model_level(model)
    
    @setup_controller[:model]            = model
    @setup_controller[:instance_name]    = nil
    @setup_controller[:model].setup_model.each do |key,value|
      @setup_controller[key] = value 
    end unless @setup_controller[:model].setup_model.blank?     
    @setup_controller[:instance_name]  ||= @setup_controller[:model].table_name.gsub("es_","").humanize.singularize

    column_setup    = @setup_controller[:model].columns_setup
    columns_screen_forced = []
    field_defined_model_or_ctrl = []
    @columns_screen = []
    @setup_controller[:model].columns.each do |column|
        tmp_columns_screen = init_default_columns_screen(column)
      

 #      get attribute from model
        exist_column_setup = column_setup.select{|col| col[:name]==column.name}
        field_defined_model_or_ctrl << column.name unless exist_column_setup.blank?
        exist_column_setup = exist_column_setup.blank? ? {} : exist_column_setup[0]
        exist_column_setup.each do |key,value|
          tmp_columns_screen[key] = value.nil? ? tmp_columns_screen[key] : value 
        end unless exist_column_setup.blank?     
               
      
        tmp_columns_screen[:hidden] = true if @setup_controller[:only_field_defined] && !field_defined_model_or_ctrl.include?(column.name)
        @columns_screen << tmp_columns_screen                          

    end

    
    #insert column added into the model with no field in the table
    #insert column added into the controller with no field in the table
    manage_field_out_of_table(column_setup,columns_screen_forced)

    #remove hide column
    @columns_screen.select! { |hsh| (hsh[:hidden]||false)==false } 
    
    #manage order of column to display
    manage_order_setup_to_display
       

    #traduction
    translate_setup
    
  end


  def init_link_to(model_name_linked)
    link = (model_name_linked || 'dummy').downcase
    
    
    link_to = @controller_link_to[link.to_sym].presence||{}
    link_to[:model_name]          = @setup_controller[:instance_name]
    link_to[:model_linked]        = model_name_linked.constantize
    link_to[:model_name_linked]   = model_name_linked.underscore.gsub("es_","").humanize.singularize.trn
    link_to[:association_type]    = get_model_assoc_type(model_name_linked)
    link_to[:title]             ||= "Liaison entre %{model_1} et %{model_2}".trn(:model_1 => link_to[:model_name], :model_2 =>link_to[:model_name_linked])
    link_to[:title_left]        ||= link_to[:model_name]
    link_to[:title_right]       ||= link_to[:model_name_linked]
    link_to[:description]       ||= "Veuillez faire une liaison entre %{model_1} et %{model_2}".trn(:model_1 => link_to[:model_name], :model_2 =>link_to[:model_name_linked])
    link_to[:query]             ||= ""
    link_to[:query_link]        ||= ""
    link_to[:query_enabled_ids] ||= ""
    link_to[:column]            ||= ""
    link_to[:column_link]       ||= ""
    link_to
  end

  def get_model_assoc_type(model_name_linked)
    as      = @setup_controller[:model].reflect_on_all_associations.select{|elem| elem.name.to_s==model_name_linked.tableize}
    return as.size > 0 ? as[0].macro.to_s : 'NA'        
  end

  def get_link_id_field_name(model_name_linked)
    return model_name_linked.underscore + "_" + (['has_and_belongs_to_many','has_many'].include?(get_model_assoc_type(model_name_linked)) ? "ids" : "id") 
  end

  def get_by_id
    id = params[:id].presence || params[:cid][0].presence || 0
    @instance = @setup_controller[:model].find(id)
    @parent = @setup_controller[:model].find_by_id(@instance.parent_id) if @setup_controller[:model].column_names.include?('parent_id')
  end
  
  def clean_msg

    flash.delete(:notice) 
    flash.delete(:error) 
    flash.delete(:waring)
    flash.delete(:errors_destroy) 
 
  end
  
  def check_children_before_delete(element)
    if element.children.count > 0
      element.errors.add(:base, "Impossible de supprimer si des enfants existent".trn)      
    end    
    element.children.count > 0
  end
  
  def initial_sequence_for(element_id)
    tmp_parent = element_id.blank? ? nil : @setup_controller[:model].find_by_id(element_id)
    order = []
    if tmp_parent
      tmp_parent.children.order('sequence asc').each_with_index do |child,index|
        order << [child.id,index+1]
      end 
    elsif @setup_controller[:parent_exists]==false
      @setup_controller[:model].order('sequence asc').all.each_with_index do |child,index|
        order << [child.id,index+1]
      end
    end
    order.each do |o|
      @setup_controller[:model].find_by_id(o[0]).update_attribute("sequence",o[1])
    end
  end

  def init_back
    session[:back_controller] = params[:controller]
    session[:back_action]     = params[:action]
    session[:back_id]         = params[:id]
    session[:back_params]     = params.except(:controller, :action, :id)
  end

  def get_old_ancestor(parent_id)
    if @setup_controller[:parent_exists]
      parent = @setup_controller[:model].find_by_id(parent_id)
      if parent.blank? 
        return @setup_controller[:model].new
      else
        return (parent.ancestors.reverse + [parent]).first
      end
    end
  end  

  def init_info_for_list(parent_id)
    if @setup_controller[:parent_exists]
      
      @parent = @setup_controller[:model].find_by_id(parent_id)
      @parent_info = "#{@setup_controller[:instance_name]} : " + (@parent.blank? ? "Origine".trn : "")
      unless @parent.blank? 
        @breadcrumb = [["Début".trn,url_for(:action=>'list',:parent_id=>0)]]
        @parent.ancestors.reverse.each do |elem|
          @breadcrumb << [elem.send(@setup_controller[:column_name_exists] ? "name" : "id"),url_for(:action=>'list',:parent_id=>elem.id)]
        end 
        @breadcrumb << [@parent.send(@setup_controller[:column_name_exists] ? "name" : "id")] 
      else
        @breadcrumb = nil
      end
    end
  end  

  
  # Builds up @sort based upon what the user has sent in params[:sort]
  def sorting(options = {})
    options[:default] ||= 'created_at DESC'                         # handling the default value
    unless params[:sort].blank?                                     # does params[:sort] contains something at least ?
      mdata = params[:sort].scan(/(?:(\S+)(_reverse)$)|(?:(\S+)$)/) # applying the regexp
      unless mdata.nil?                                             # if it returned something
        mdata = mdata[0]                                            # we retrieving the match items array
#        tmp_sort = (mdata[0].nil? ? mdata[2] : "#{mdata[0]} DESC")
        tmp_sort = (mdata[0].nil? ? mdata[2] : mdata[0].split(',').map{|f| "#{f} DESC"}.join(",") )
        @sort=[]
        @sort << (tmp_sort.split('.').count > 1 ? (tmp_sort.split('.')[-2].pluralize + ".") : "") + tmp_sort.split('.').last
        list_table = tmp_sort.split('.').count <= 1 ? "" : tmp_sort.split('.')[0..-2].join('.')
        @sort << (list_table.blank? ? nil : list_table.split('.').reverse[1..-1].inject(list_table.split('.').last.to_sym) { |b, n| {n.to_sym =>b} })   
      end
    end                                                             # if ever it hasn't been initialized
    @sort ||= [options[:default],nil]                                     # @sort is filled with the default value
    

  end
  
  def detect_association(instance,exception_models=[])
    linked=[]
    @setup_controller[:model].reflect_on_all_associations.each do |elem|
      unless exception_models.include?(elem.name.to_s)
        case elem.macro.to_s
#          when "belongs_to", "has_one"
#            tmp_obj = instance.send(elem.name)
#            linked ||= !tmp_obj.blank?
        when "has_many", "has_and_belongs_to_many"
          linked << elem.name.to_s.humanize if  instance.send(elem.name).count > 0
        end
      end        
   end
   return linked
  end


  def transform_list(element)    
    element.each do |k,v|
      column = @columns_screen.select{|col| col[:name]==k.to_s}[0]
      unless column.blank?
        if v.is_a?(Array) && column[:type]=='list_multi'
          list=[]
          v.each do |elem|
            list << elem if column[:value_list].split(',').include?(elem)
          end
          element[k]=list.join(',')
        elsif column[:type]=='list_free'
          element[k] = v.split("\n").map{|line| line.strip}.join(',')
        end
      end    
    end    
  end

  def translate_setup
    @setup_controller[:instance_name]=@setup_controller[:instance_name].trn
    @columns_screen.each do |column|
      [:column_name,:column_text,:label_name,:info].each do |attr|
         column[attr] = column[attr].trn unless column[attr].blank?
      end
    end
  end

  def manage_order_setup_to_display
    tmp_columns_order = @columns_screen.collect{|hsh|hsh[:order]||0}
    index=0    
    @columns_screen.each do |hsh| 
      
      if hsh[:display_edit] && hsh[:order].blank?
        begin 
          index+=1
        end while tmp_columns_order.include?(index)
        hsh[:order]= index
      end
      
      #load model linked if exist
      begin
        hsh[:model_linked].constantize unless hsh[:model_linked].blank?
      rescue
      end
    end

    #sort column by order
    @columns_screen = @columns_screen.sort_by { |hsh| hsh[:order]||0 }    
  end
  
  def init_default_columns_screen(column)
    return        {name:                column.name,
                   order:               nil,
                   column_name:         (column.name[-3..-1] == '_id' ? column.name[0..-4].gsub("es_","") : column.name).humanize,
                   column_text:         "",
                   label_name:          (column.name[-3..-1] == '_id' ? column.name[0..-4].gsub("es_","") : column.name).humanize,
                   type:                (column.type.to_s=="string" && column.limit==1 && ["Y","N"].include?(column.default)) ? "boolean" : column.type.to_s,
                   checked_value:       (column.type.to_s=="string" && column.limit==1 && ["Y","N"].include?(column.default)) ? 'Y' : nil,
                   unchecked_value:     (column.type.to_s=="string" && column.limit==1 && ["Y","N"].include?(column.default)) ? 'N' : nil,
                   linked_name:         column.name.match(/_id$/) ? column.name.gsub(/_id$/, '') : nil,
                   model_linked:        column.name.match(/_id$/) ? column.name.gsub(/_id$/, '').classify : nil,
                   model_linked_field:  column.name.match(/_id$/) ? "name" : nil,
                   linked_to_model:     false,
                   display_new:         !["id","created_at","updated_at","sequence","es_site_id","creator_id","updater_id","created_by","updated_by","read_only","model_type"].include?(column.name),
                   display_show:        !["id","created_at","updated_at","es_site_id","creator_id","updater_id","created_by","updated_by","read_only","model_type"].include?(column.name),
                   display_edit:        !["id","created_at","updated_at","es_site_id","creator_id","updater_id","created_by","updated_by","read_only","model_type"].include?(column.name),
                   display_list:        !["id","created_at","updated_at","es_site_id","creator_id","updater_id","created_by","updated_by","read_only","active","model_type"].include?(column.name),
                   value_list:          (column.type.to_s=="string" && column.limit==1 && ["Y","N"].include?(column.default)) ? 'Y,N' : nil,
                   link_update:         ["name","code"].include?(column.name),
                   sort:                ["name","code"].include?(column.name),
                   search:              ["name","code"].include?(column.name),
                   dynamic_filter:      ["name","code","description"].include?(column.name),
                   dynamic_search:      ["name","code","description"].include?(column.name),
                   length_field:        [column.limit||0,40].min,
                   length_value:        [column.limit||0,400].min,
                   length_field_filter: [column.limit||0,15].min,
                   hidden:               false
                  } 
  end

  def manage_field_out_of_table(column_screen_model,columns_screen_ctrl)
    #insert column added into the model with no field in the table
    column_screen_model.select{|col| !@setup_controller[:model].column_names.include?(col[:name]||'')}.each do |new_column|
      @columns_screen << new_column      
    end

    #insert column added into the controller with no field in the table
    columns_screen_ctrl.each do |new_column|
      @columns_screen << new_column      
    end    
  end
    
end
