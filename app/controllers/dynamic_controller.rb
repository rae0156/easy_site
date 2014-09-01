# encoding: UTF-8

class DynamicController < ApplicationController
  include PDFHelper

  before_filter :init_back, :only => ["list","index"]
  before_filter :get_by_id, :only => ["edit", "update", "destroy","down","up","activate"]
  before_filter :clean_msg, :only => ["edit", "update", "destroy"]

  def initialize()
     
    #self.class.load_and_authorize_resource
    self.class.before_filter :login_required 
    
    
    @controller_link_to                  ||= {}
    @controller_setup                    ||= {}
    @controller_setup[:controller_name]  ||= controller_name
    @controller_setup[:model]            ||= controller_name.classify.constantize
    @controller_setup[:instance_name]    ||= @controller_setup[:model].table_name.gsub("es_","").humanize.singularize

    @controller_setup[:model].setup_model.each do |key,value|
      @controller_setup[key] = value 
    end unless @controller_setup[:model].setup_model.blank?     

    column_setup = @controller_setup[:model].columns_setup
    
    columns_screen_forced = @columns_screen||[] 
    @columns_screen = []
    @controller_setup[:model].columns.each do |column|
      tmp_columns_screen ={name:                column.name,
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
                   display_new:         !["id","created_at","updated_at","sequence","es_site_id","creator_id","updater_id","read_only"].include?(column.name),
                   display_show:        !["id","created_at","updated_at","es_site_id","creator_id","updater_id","read_only"].include?(column.name),
                   display_edit:        !["id","created_at","updated_at","es_site_id","creator_id","updater_id","read_only"].include?(column.name),
                   display_list:        !["id","created_at","updated_at","es_site_id","creator_id","updater_id","read_only"].include?(column.name),
                   value_list:          (column.type.to_s=="string" && column.limit==1 && ["Y","N"].include?(column.default)) ? 'Y,N' : nil,
                   link_update:         ["name","code"].include?(column.name),
                   sort:                ["name","code"].include?(column.name),
                   search:              ["name","code"].include?(column.name),
                   dynamic_filter:      ["name","code","description"].include?(column.name),
                   dynamic_search:      ["name","code","description"].include?(column.name),
                   length_field:        [column.limit||0,40].min,
                   length_value:        [column.limit||0,400].min,
                   length_field_filter: [column.limit||0,15].min,
                   hide:                false
                  } #unless @columns_screen.collect{ |col| col[:name]}.include?(column.name)
      
#      new_columns_screen = {}
#      exist_columns_screen= columns_screen_forced.select{ |col| col[:name]==column.name}
#      exist_columns_screen= exist_columns_screen.blank? ? {} : exist_columns_screen[0]
#      columns_screen_forced.delete_if{ |col| col[:name]==column.name}      
#      tmp_columns_screen.each do |key,value|
#        new_columns_screen[key] = exist_columns_screen[key].nil? ? value : exist_columns_screen[key] 
#      end
#      @columns_screen.delete_if{ |col| col[:name]==column.name}
#      @columns_screen << new_columns_screen



#      get attribute from model
      exist_column_setup = column_setup.select{|col| col[:name]==column.name}
      exist_column_setup = exist_column_setup.blank? ? {} : exist_column_setup[0]
      exist_column_setup.each do |key,value|
        tmp_columns_screen[key] = value.nil? ? tmp_columns_screen[key] : value 
      end unless exist_column_setup.blank?     
               
#      merge forced attribute
      new_columns_screen = {}
      exist_columns_screen = columns_screen_forced.select{|col| col[:name]==column.name}
      exist_columns_screen = exist_columns_screen.blank? ? {} : exist_columns_screen[0]
      columns_screen_forced.delete_if{ |col| col[:name]==column.name}
      tmp_columns_screen.each do |key,value|
        new_columns_screen[key] = exist_columns_screen[key].nil? ? value : exist_columns_screen[key] 
      end      
      @columns_screen << new_columns_screen                          


    end
    
    #insert column added into the controller
    columns_screen_forced.each do |new_column|
      @columns_screen << new_column      
    end

    #remove hide column
    @columns_screen.select! { |hsh| (hsh[:hide]||false)==false } 
    
    #manage order of column to display
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
       

    @controller_setup[:mandatory_exists]       ||= @columns_screen.select{ |col| col[:mandatory]}.count > 0
    @controller_setup[:dynamic_filter_exists]  ||= @columns_screen.select{ |col| col[:dynamic_filter]}.count > 0
    @controller_setup[:dynamic_search_exists]  ||= @columns_screen.select{ |col| col[:dynamic_search]}.count > 0
    @controller_setup[:parent_exists]          ||= @columns_screen.collect{ |col| col[:name]}.include?("parent_id")
    @controller_setup[:sequence_exists]        ||= @columns_screen.collect{ |col| col[:name]}.include?("sequence")
    @controller_setup[:category_exists]        ||= @columns_screen.collect{ |col| col[:name]}.include?("es_category_id")
    @controller_setup[:column_name_exists]     ||= @columns_screen.collect{ |col| col[:name]}.include?("name")
    @controller_setup[:default_column_name]    ||= @controller_setup[:column_name_exists] ? "name" : (@columns_screen.collect{ |col| col[:name]}.include?("code") ? "code" : "id")
    @controller_setup[:default_sort]           ||= @controller_setup[:sequence_exists] ? "sequence" : "id"
    @controller_setup[:table_field_active]     ||= @columns_screen.collect{ |col| col[:name]}.include?("active")
    @controller_setup[:delete_if_used]           = @controller_setup[:delete_if_used].nil? ? false : @controller_setup[:delete_if_used] 
    @controller_setup[:delete_if_inactive]       = @controller_setup[:delete_if_inactive].nil? ? false : @controller_setup[:delete_if_inactive] 
    @controller_setup[:delete_multi]             = @controller_setup[:delete_multi].nil? ? false : @controller_setup[:delete_multi] 
    @controller_setup[:readonly_exists]        ||= @columns_screen.collect{ |col| col[:name]}.include?("read_only")
    @controller_setup[:readonly_exists]        ||= @columns_screen.collect{ |col| col[:name]}.include?("read_only")
    @controller_setup[:search_exists]          ||= @columns_screen.select{ |col| col[:search]}.count > 0

    #traduction
    @controller_setup[:instance_name]=@controller_setup[:instance_name].trn
    @columns_screen.each do |column|
      [:column_name,:column_text,:label_name].each do |attr|
         column[attr] = column[attr].trn unless column[attr].blank?
      end
    end
    @controller_link_to.each do |k,v|
      [:title,:description,:title_left,:title_right].each do |attr|
        @controller_link_to[k][attr]        =v[attr].trn unless v[attr].blank?     
      end
    end

    super
  end

  # Load the pages -
  def list
    parent_id= nil   
    if params[:parent_id].presence 
      #sans recherche
      parent_id = params[:parent_id]
      session[:parent_id]=""
    else
      #avec recherche
      parent_id = session[:parent_id]
    end

    ####################################### tri ####################################### 

    sorting :default => "#{@controller_setup[:model].table_name}.#{@controller_setup[:default_sort]}"
    
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
    if @controller_setup[:parent_exists]
      if parent_id.blank?
        tmp_search[:parent_id]=0
      else
        tmp_search[:parent_id]=parent_id
      end
      #ne pas mettre en commentaire, car les filtres et recherches ne fonctionnent plus
      session[:parent_id] = parent_id unless parent_id.blank?
    end
    conditions = DynamicSearch.new(@controller_setup[:model],tmp_search).build_conditions #.accessible_by(current_ability)
    ####################################### init info ####################################### 
    
    init_info_for_list(parent_id)

    ####################################### pagination ####################################### 

    session[:conditions] = tmp_search
    session[:sort] = @sort
#    @instances = @controller_setup[:model].paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => conditions

    @instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).page(params[:page])

    ####################################### retour ####################################### 

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
      @instance = @controller_setup[:model].find_by_id(params[:id])
  
      render "shared/dynamic/show"
  end


  def show_setup
    
    tmp_text = "<H1>Controller '<a href=""#{'list'}"">#{@controller_setup[:controller_name]}</a>'</H1>" 
    tmp_text += "<H2>Setup :</H2>" 
    @controller_setup.sort.each do |k,v|
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
    element = @controller_setup[:model].find(:first, :conditions => ["parent_id = ? and sequence=?","#{@instance.parent_id}",@instance.sequence + 1])
    unless element.blank?
      element.update_attribute("sequence",order) 
      @instance.update_attribute("sequence",order + 1) 
    end
    redirect_to :action => "list", :parent_id => @instance.parent_id
  end

  #move up
  def up
    order = @instance.sequence
    element = @controller_setup[:model].find(:first, :conditions => ["parent_id = ? and sequence=?","#{@instance.parent_id}",@instance.sequence - 1])
    unless element.blank?
      element.update_attribute("sequence",order) 
      @instance.update_attribute("sequence",order - 1) 
    end
    redirect_to :action => "list", :parent_id => @instance.parent_id
  end


  
  #Create an empty new in order to be used in the new new screen -
  def new
    @instance = @controller_setup[:model].new()
    @parent = @controller_setup[:parent_exists] && params[:parent_id] && params[:parent_id].to_i > 0 ? @controller_setup[:model].find_by_id(params[:parent_id]) : nil 
    @back_to_parent = (@parent.blank? || @parent.ancestors.count == 0 ? "" : (@parent.children.count == 0 ? @parent.ancestors[0].id : @parent.id))
    render "shared/dynamic/new"
  end
   
  # Save the New to database -
  def create
    params[:instance][:sequence]=999999999 if @controller_setup[:sequence_exists]
    transform_list(params[:instance])
    @instance = @controller_setup[:model].new(params[:instance])
    if @instance.save

      initial_sequence_for(@instance.parent_id) if @controller_setup[:sequence_exists]

      flash[:notice] = "'%{element_dynamique}' créé avec succès.".trn(:element_dynamique => @controller_setup[:instance_name])

      if @controller_setup[:parent_exists]
        redirect_to :action => "list", :parent_id => params[:instance][:parent_id]
      else
        redirect_to :action => "list"
      end
    else
      params[:action]="new"
      render "shared/dynamic/new"
    end
  end
  
  def edit
    render "shared/dynamic/edit"
  end
  
  def update
    transform_list(params[:instance])
    if @instance.update_attributes(params[:instance])
      flash[:notice] = "'%{element_dynamique}' a été correctement modifié".trn(:element_dynamique => @controller_setup[:instance_name]) +"."
      if @controller_setup[:parent_exists]
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
      flash[:notice] = "%{element_dynamique} a été activé.".trn(:element_dynamique=> @controller_setup[:instance_name])
      redirect_to :action => "list",:page=> params[:page]
    else
      destroy = !detect_association(@instance).blank? ? @controller_setup[:delete_if_used] : @controller_setup[:delete_if_inactive]
      unless destroy 
        @instance.update_attribute('active',@instance.active=='Y' ? 'N' : 'Y')    
        flash[:notice] = "%{element_dynamique} a été #{@instance.active=='Y' ? 'activé' : 'désactivé'}.".trn(:element_dynamique=> @controller_setup[:instance_name])
        redirect_to :action => "list",:page=> params[:page]
      else
        redirect_to :action => "destroy",:id=> params[:id]      
      end
    end
  end  
  
  def destroy

    tmp_element_error = @controller_setup[:model].new
    for id in params[:cid]
      tmp = @controller_setup[:model].find(id)
      back_to_parent = @controller_setup[:parent_exists] && tmp.ancestors.count > 0 ? (tmp.ancestors[0].children.count > 1 ? tmp.parent_id : tmp.ancestors[0].parent_id) : ""      
      
      if @controller_setup[:readonly_exists] && tmp["read_only"]=='Y'
        tmp_element_error.errors.add(:base, "La suppresison de '%{element_dynamique}' ne peut être faite, cet élément est en lecture seule.".trn(:element_dynamique => @setup_controller[:model_name].singularize))
      elsif !@controller_setup[:delete_if_used] && !detect_association(@instance).blank?
        tmp_element_error.errors.add(:base, "La suppresison de '%{element_dynamique}' ne peut être faite, car des liaisons existent.".trn(:element_dynamique => @setup_controller[:model_name].singularize))
      elsif check_children_before_delete(tmp) || !tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "'#{@controller_setup[:instance_name]} - #{tmp.name}' : #{tmp_error}")
        end
      else
        initial_sequence_for(tmp.parent_id)
      end
    end unless params[:cid].blank?
    
    unless params[:id].blank?
      @instance = @controller_setup[:model].find_by_id(params[:id])
      detect = detect_association(@instance)
      if detect_association(@instance).blank? || @controller_setup[:delete_if_used]
        @instance.destroy unless @instance.blank?
      else
        tmp_element_error.errors.add(:base, "La suppresison de '%{element_dynamique}' ne peut être faite, car des liaisons existent".trn(:element_dynamique => @controller_setup[:instance_name].humanize) + ". (#{detect.join(', ')})")
      end
    end    
    
    if tmp_element_error.errors.empty? 
      flash[:notice] = "'%{element_dynamique}' correctement supprimé(s).".trn(:element_dynamique => @controller_setup[:instance_name]) 
    else
      flash[:errors_destroy] = tmp_element_error
    end
    if @controller_setup[:parent_exists]
      redirect_to :action => "list", :parent_id => back_to_parent
    else
      redirect_to :action => "list"
    end
  end

  def export_pdf

    file_name = "rapport_pdf_#{@controller_setup[:model].table_name}_#{Time.zone.now.strftime("%Y%m%d%H%M%S%L")}.pdf"
    pdf = Prawn::Document.new

    #Create the first page
    create_title_page(pdf, "Liste".trn + " - #{@controller_setup[:instance_name]}","Date et Heure".trn + " : #{Time.zone.now.strftime("%d/%m/%Y %H:%M:%S")}" ) 
    
    pdf.start_new_page()
    pdf.font_size 12
    
    # Find all New with the stored restrictions
    conditions = DynamicSearch.new(@controller_setup[:model],session[:conditions]).build_conditions.accessible_by(current_ability)
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

  def export_csv
    # Find all New with the stored restrictions
    conditions = DynamicSearch.new(@controller_setup[:model],session[:conditions]).build_conditions.accessible_by(current_ability)
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
    file_name = "#{@controller_setup[:model].model_name.underscore}_export_#{Date.today.strftime("%Y-%m-%d %H:%M:%S")}" + ".csv"
    download_csv(csv_string, file_name)

  end
  


  def contenttree
    param_dir = params[:dir]||''

    parent_id = ""
    parent_id = param_dir.end_with?('/') ? param_dir[0...-1] : param_dir unless param_dir.blank?

    if parent_id.blank?
      conditions = ["(#{@controller_setup[:model].table_name}.parent_id IS NULL OR #{@controller_setup[:model].table_name}.parent_id = 0)"]
    else
      conditions = ["(#{@controller_setup[:model].table_name}.parent_id = ?)","#{parent_id}"]
    end
    instances = @controller_setup[:model].find :all, :order => @controller_setup[:default_sort], :conditions => conditions

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
  
  
  def viewtree
    param_dir = params[:dir] || '' 

    tmp_search={}
    if param_dir.blank?
      tmp_search[:parent_id]=nil
    elsif param_dir.end_with?('/')
      tmp_search[:parent_id] = param_dir[0...-1]     
    else
      tmp_search[:id] = param_dir    
    end
    conditions = DynamicSearch.new(@controller_setup[:model],tmp_search).build_conditions.accessible_by(current_ability)
    
    
    ####################################### init info ####################################### 
    
    init_info_for_list(tmp_search[:parent_id])

    ####################################### pagination ####################################### 

    session[:conditions] = tmp_search
    @instances = conditions.includes(session[:sort][1]).order(session[:sort][0]).page(params[:page])
    #@instances = @controller_setup[:model].paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => conditions

    @element_id, @partial = 'dynamic_list_div', 'shared/dynamic/list'
    render 'shared/replace_content', :formats => [:js]
  end

  def link_to
    @model_link = params[:id].presence.blank? ? nil : @controller_setup[:model].find_by_id(params[:id])
    @link_to = init_link_to(params[:link])
    @instances = @controller_setup[:model].where(@link_to[:query]).page(params[:page])
    @instances_to_link = @link_to[:model_linked].where(@link_to[:query_link]).page(params[:page])
    @enabled_ids = @controller_setup[:model].where(@link_to[:query_enabled_ids]).collect(&:id)
    link_id_string = get_link_id_field_name(params[:link]) 
    @model_linked_list_ids = @model_link.blank? ? nil : @model_link.send(link_id_string)
    render "shared/dynamic/link_to" 
  end

  def link_to_model
    element = @controller_setup[:model].find_by_id(params[:id])
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

  def init_link_to(model_name_linked)
    link = (model_name_linked || 'dummy').downcase
    
    
    link_to = @controller_link_to[link.to_sym].presence||{}
    link_to[:model_name]          = @controller_setup[:instance_name]
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
    as      = @controller_setup[:model].reflect_on_all_associations.select{|elem| elem.name.to_s==model_name_linked.tableize}
    return as.size > 0 ? as[0].macro.to_s : 'NA'        
  end

  def get_link_id_field_name(model_name_linked)
    return model_name_linked.underscore + "_" + (['has_and_belongs_to_many','has_many'].include?(get_model_assoc_type(model_name_linked)) ? "ids" : "id") 
  end

  def get_by_id
   
    id = params[:id].presence || params[:cid][0].presence || 0
    @instance = @controller_setup[:model].find(id)
    @parent = @controller_setup[:model].find_by_id(@instance.parent_id) if @controller_setup[:parent_exists]

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
    tmp_parent = element_id.blank? ? nil : @controller_setup[:model].find(element_id)
    order = []
    tmp_parent.children.each_with_index do |child,index|
      order << [child.id,index+1]
    end if tmp_parent
    order.each do |o|
      @controller_setup[:model].find(o[0]).update_attribute("sequence",o[1])
    end
  end

  def init_back
    session[:back_controller] = params[:controller]
    session[:back_action]     = params[:action]
    session[:back_id]         = params[:id]
    session[:back_params]     = params.except(:controller, :action, :id)
  end

  def init_info_for_list(parent_id)
    if @controller_setup[:parent_exists]
      @parent = @controller_setup[:model].find_by_id(parent_id)
      @parent_info = "#{@controller_setup[:instance_name]} : " + (@parent.blank? ? "Origine".trn : "")
      unless @parent.blank? 
        @breadcrumb = [["Début".trn,url_for(:action=>'list')]]
        @parent.ancestors.reverse.each do |elem|
          @breadcrumb << [elem.send(@controller_setup[:column_name_exists] ? "name" : "id"),url_for(:action=>'list',:parent_id=>elem.id)]
        end 
        @breadcrumb << [@parent.send(@controller_setup[:column_name_exists] ? "name" : "id")] 
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
  
  def detect_association(instance)
    linked=[]
    @controller_setup[:model].reflect_on_all_associations.each do |elem|
       case elem.macro.to_s
#          when "belongs_to", "has_one"
#            tmp_obj = instance.send(elem.name)
#            linked ||= !tmp_obj.blank?
          when "has_many", "has_and_belongs_to_many"
            linked << elem.name.to_s.humanize if  instance.send(elem.name).count > 0
       end
   end
   return linked
  end


  def transform_list(element)    
    element.each do |k,v|
      column = @columns_screen.select{|col| col[:name]==k.to_s}[0]
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
