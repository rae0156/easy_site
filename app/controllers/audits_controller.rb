require "date"
class AuditsController < ApplicationController


  VIEWS = {
            :version => {
                          :model        => "AuditByVersion",
                          :subquery     => {:conditions => "auditable_type = ? AND auditable_id = ?", :include => [:es_user], :fields => ["auditable_type","auditable_id"], :sort => "version DESC", :id_fields => "id", :remove_old_conditions => true},
                          :field_group  => "version",
                          :name         => "Par version".trn
                        },
            :date => {
                          :model        => "select distinct DATE_FORMAT(audits.created_at,'%d-%m-%Y') created_at FROM audits",
                          :sort         => "created_at desc",
                          :subquery     => {:conditions => "DATE_FORMAT(created_at,'%d-%m-%Y') = ?", :include => [:es_user], :fields => ["created_at"], :sort => "audits.id DESC", :id_fields => "created_at", :remove_old_conditions => false},
                          :field_group  => "date",
                          :name         => "Par date".trn
                        },
            :date_user => {
                          :model        => "select distinct DATE_FORMAT(audits.created_at,'%d-%m-%Y') created_at, audits.user_id  FROM audits JOIN es_users on es_users.id = audits.user_id",
                          :sort         => "created_at desc",
                          :subquery     => {:conditions => "DATE_FORMAT(created_at,'%d-%m-%Y') = ? AND user_id = ?", :include => [:es_user], :fields => ["created_at","user_id"], :sort => "audits.id DESC", :id_fields => "created_at,user_id", :remove_old_conditions => false},
                          :field_group  => "date_user",
                          :name         => "Par date et utilisateur".trn
                        },
            :user_date => {
                          :model        => "select distinct audits.user_id,DATE_FORMAT(audits.created_at,'%d-%m-%Y') created_at  FROM audits JOIN es_users on es_users.id = audits.user_id",
                          :sort         => "user_id, created_at desc",
                          :subquery     => {:conditions => "DATE_FORMAT(created_at,'%d-%m-%Y') = ? AND user_id = ?", :include => [:es_user], :fields => ["created_at","user_id"], :sort => "audits.id DESC", :id_fields => "created_at,user_id", :remove_old_conditions => false},
                          :field_group  => "user_date",
                          :name         => "Par utilisateur et par date".trn
                        },
            :object_type => {
                          :model        => "select distinct audits.auditable_type_label FROM audits JOIN es_users on es_users.id = audits.user_id",
                          :sort         => "auditable_type_label",
                          :subquery     => {:conditions => "auditable_type_label = ?", :include => [:es_user], :fields => ["auditable_type_label"], :sort => "audits.id DESC", :id_fields => "auditable_type_label", :remove_old_conditions => false},
                          :field_group  => "object_type",
                          :name         => "Par type d'objet".trn
                        }
          }
    
  
  # Load the pages -
  def index

    @audit = nil
    session[:object] = (params[:object] ||  session[:object])   
    #partial_name     = (session[:object] || 'list').downcase
    partial_name =  (session[:object] ? eval(session[:object]).table_name.singularize : 'list').downcase
    
    generate_audits_filters(session[:object])
    paginate_audits(session[:object], nil)

    respond_to do |format|
      format.html { render :action => partial_name }
      format.js do
        @element_id, @partial = 'audits_div', 'list'
        render 'shared/replace_content'
      end #end format
    end #end respond_to

  end

  alias_method :refresh, :index
  alias_method :list, :index

  def show
    @audit = Audit.find(params[:id])
    respond_to do |format|
      format.html {}
      format.js do
        @element_id, @partial = 'show_div', 'show'
        render 'shared/replace_content'
      end #end format
    end #end respond_to
  end
  
  def display_group
    
    view = VIEWS[params[:link_group].to_sym][:subquery]

    remove_old_conditions = view[:remove_old_conditions].present? ? true : view[:remove_old_conditions]        
    unless remove_old_conditions
      conditions = []
      session[:where_clause].each do |elem|
        conditions << elem.clone    
      end
    else
      conditions = [""]
    end
    if view[:id_fields] == "id" 
      audit = Audit.find_by_id(params[:id].gsub("group_by_",""))
      conditions[0] << " AND " unless conditions[0].blank? 
      conditions[0] << "(#{view[:conditions]})" 
      view[:fields].each do |f|
        conditions << audit[f]
      end
    else
      ids = params[:id].gsub("group_by_","").split('_')
      id_fields = view[:id_fields].split(",")
      id_field_array = {}
      id_fields.each_with_index do |id_f,i|
        id_field_array[id_f.to_sym] = ids.length == id_fields.length ? ids[i].gsub("-blank-", " ") : "" 
      end
      conditions[0] << " AND " unless conditions[0].blank? 
      conditions[0] << "(#{view[:conditions]})" 
      view[:fields].each do |f|
        conditions << id_field_array[f.to_sym].presence
      end
    end
    
    @detail_groups = Audit.find(:all, :conditions => conditions, :order => view[:sort], :include => view[:include])
  
    respond_to do |format|
      format.js do
        @element_id, @partial = params[:id].gsub("group_by_","div_group_"), 'list_group'
        render 'shared/replace_content'
      end #end format
    end #end respond_to
  end
  
  
 private
 
  
  def generate_audits_filters(dtype=nil)
    set_view_types
    
    set_object_types
    
    set_dates


    if params[:audit]
      created_by            = params[:audit][:user_id]||'All'
      action                = params[:audit][:action] 
      ltype                  = params[:audit][:type]
      auditable_id          = params[:audit][:auditable_id]
      auditable_id          = "%#{auditable_id.upcase}%" unless auditable_id.blank? 
      entity_code           = params[:audit][:entity_code] unless params[:audit][:entity_code].blank? 
    end
    
    conditions  = ['']
    {
      dtype                             => 'audits.auditable_type = ?'  ,
      (created_by||'').upcase           => '(UPPER(es_users.mail) = ? OR UPPER(es_users.pseudo) = ?)',
      auditable_id                      => "UPPER(audits.auditable_label) LIKE ?",
      action                            => 'audits.action = ?'           ,
      ltype                             => "(audits.auditable_type_label = ? ) OR (audits.auditable_type_label IS NULL AND audits.auditable_type = ?)",
      @from_date                        => 'audits.created_at >= ?',
      (Date.parse(@to_date) + 1).to_s   => 'audits.created_at < ?',
      entity_code                       => 'audits.auditable_id IN (select distinct aec.auditable_id from AUDITS aec where aec.changes like \'%entity_text:%\'||?||\'%\')'
    }.each_pair do |value, condition|
      unless value.blank? or value == 'All'
        operator      =  " AND " unless conditions[0].empty?
        conditions[0] << "#{operator} (#{condition})"
        condition.count("?").times do
          conditions    << value
        end        
      end
    end
    session[:where_clause] = conditions.clone
    flash[:audit_conditions] = conditions
    
  end

  def paginate_audits(object, id)
    sorting :default => 'audits.created_at desc, audits.auditable_type asc, audits.auditable_id asc, audits.version desc'
    
    unless flash[:audit_conditions].nil?                  
      @conditions = flash[:audit_conditions]        
    else
      @conditions = ['']
      @conditions [0]<<  "audits.created_at >= ?"
      @conditions    <<  @from_date
    end

    if(!object.nil? and !id.nil?)
      sorting :default => 'audits.version desc'
      
      operator = " AND " unless @conditions[0].empty?
      @conditions[0] <<  "#{operator} audits.auditable_type = ?"
      @conditions    <<  object
      
      operator = " AND " unless @conditions[0].empty?
      @conditions[0] <<  "#{operator} audits.auditable_id = ?"
      @conditions    <<  id
    end
    
    if VIEWS[@view.to_sym].present?
      sql_or_model = VIEWS[@view.to_sym][:model]
      sort = VIEWS[@view.to_sym][:sort].presence || ""
      if sql_or_model.split(' ').length > 1        
        @conditions[0] = sql_or_model + " WHERE " + @conditions[0] + (sort.blank? ? "" : " order by " + sort) 
        @audits = Audit.paginate_by_sql @conditions, :per_page => 100, :page => params[:page]
      else        
        model = sql_or_model.constantize
        conditions = []
        @conditions.each do |c|
          conditions << c.clone
        end
        conditions[0].gsub!("audits.", "#{model.table_name}.")
        sort = @sort.gsub("audits.", "#{model.table_name}.")
        @audits = model.paginate :per_page => 100, :page => params[:page],:order => sort, :conditions => conditions , :include => [:es_user]        
      end
      
      @link_group = VIEWS[@view.to_sym][:field_group]
    else
      @audits = Audit.paginate :per_page => 100, :page => params[:page],:order => @sort, :conditions => @conditions, :include => [:es_user]
      @link_group = ""
    end
  end

private

  def set_object_types
    sql  = "SELECT DISTINCT                                                        "
    sql += "  a.AUDITABLE_TYPE type_obj,                                           "
    sql += "  a.AUDITABLE_TYPE_LABEL label                                         "
    sql += "  FROM                                                                 "
    sql += "  audits a                                                      "

    audits = Audit.find_by_sql(sql)
    
#    get a list of model that exists and must have 
    model_list=[""]
    audits.each do |a|
      to_display = true
      begin
        class_model = a.type_obj.constantize
        to_display = !class_model.not_displayed_in_choices if !class_model.blank? && class_model.respond_to?('not_displayed_in_choices')
      rescue
      end      
      model_list << a.type_obj if !a.type_obj.blank? && to_display  
    end
    @object_type_lists=model_list
    audits.each do |a|
      label = ""
      unless a.label.blank?
        label = a.label if model_list.include?(a.type_obj)
        @object_type_lists = @object_type_lists - [a.type_obj]
      end        
      @object_type_lists << label unless label.blank?
    end
    @object_type_lists.sort!.uniq!
  end


  def set_dates
    @from_date  ||= params[:audit].present? && params[:audit][:from_date].present? ? params[:audit][:from_date] : (Date.today - 6).to_s
    @to_date    ||= params[:audit].present? && params[:audit][:to_date].present? ? params[:audit][:to_date] : Date.today.to_s
    @when       ||= params[:audit].present? && params[:audit][:when].present? ? params[:audit][:when] : 'other'
    case @when
      when "this_year"
        @from_date  = Date.new(Date.today.year,1,1).to_s
        @to_date    = Date.today.to_s    
      when "last_month"
        date_from = (Date.today - 1.month)
        date_to   = (Date.new(date_from.year,date_from.month,1) + 1.month) - 1
        @from_date  = Date.new(date_from.year,date_from.month,1).to_s
        @to_date    = date_to.to_s
      when "this_month"
        @from_date  = Date.new(Date.today.year,Date.today.month,1).to_s
        @to_date    = Date.today.to_s
      when "last_week"
        date_from = (Date.today - 1.week) - Date.today.wday + 1
        @from_date  = date_from.to_s
        @to_date    = (date_from + 6).to_s
      when "this_week"
        @from_date  = (Date.today - Date.today.wday + 1).to_s
        @to_date    = Date.today.to_s
      when "yesterday"
        @from_date  = (Date.today  - 1).to_s
        @to_date    = (Date.today  - 1).to_s
      when "today"
        @from_date  = Date.today.to_s
        @to_date    = Date.today.to_s    
    end
  end

  def set_view_types
    @view_types = [["Normal".trn,"normal"]] + VIEWS.map{|k,e| [e[:name],e[:field_group]]}
    @view = (params[:audit].present? && params[:audit][:views].present? ? params[:audit][:views] : nil) || 'normal'
  end

end
