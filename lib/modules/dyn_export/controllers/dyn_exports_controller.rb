# encoding: UTF-8
class DynExportsController < DynamicController

   has_es_interface_controllers
  
   def initialize()
    
    @setup_controller = {
                          :instance_name        => "Exportation dynamique",
                          :list_options => [
                                            {:text => "Details".trn,:controller => "dyn_exports", :action => "details", :glyphicon_bootstrap => "glyphicon-pencil"},
                                            {:text => "Execute to CSV".trn,:controller => "dyn_exports", :action => "execute", :params => {:export_type => "CSV"}, :glyphicon_bootstrap => "glyphicon-th-list"},
                                            {:text => "Execute to XLS".trn,:controller => "dyn_exports", :action => "execute", :params => {:export_type => "XLS"}, :glyphicon_bootstrap => "glyphicon-list-alt"}
                                           ]  
                        }
    
    @columns_screen=[
                     { :name              => "code",
                       :column_name       => "Code".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false,
                       :search            => false
                      },
                     { :name              => "name",
                       :link_show         => false,
                       :link_update       => false,
                       :column_name       => "Nom".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false,
                       :search            => false
                      },
                     { :name              => "description",
                       :column_name       => "Description".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false
                      },
                     { :name              => "active",
                       :column_name       => "Activé".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false
                      }
                      ]
    super
  end 

  def export_csv
    export=DynExport.find_by_code(params[:code])
    params[:id]           = export.id if export
    params[:export_type]  = "CSV"
    params[:old_url]      = request.env["HTTP_REFERER"]||url_for(root_url)
    execute
  end

  def export_xls
    export=DynExport.find_by_code(params[:code])
    params[:id]           = export.id if export
    params[:export_type]  = "XLS"    
    params[:old_url]      = request.env["HTTP_REFERER"]||url_for(root_url)
    execute
  end

  def execute
    old_url = params[:old_url]||request.env["HTTP_REFERER"]
    id = params[:id] || 0   
    export_type = params[:export_type]||'IT'    
    dyn_export = DynExport.find_by_id(id)
    @sql_text  = ""
    if dyn_export
      
      if dyn_export.active == 'N'
        flash[:error] = "Le rapport '%{report_name}' n'est pas activé".trn(:report_name => dyn_export.report_name)  
        redirect_to old_url
      else
        vars = dyn_export.get_where_var 
        var_values = params[:vars]||[]
        
        if vars.blank? || !var_values.blank? 
          errors = execute_query(dyn_export,export_type,var_values)
          unless errors.blank?
            flash[:error] = errors.join('<BR>').html_safe          
            redirect_to old_url
          else
            case export_type
              when "SQL"                 
                flash[:notice] = "Resultat : %{nbr} enregistrement(s) --> %{sql}".trn(:nbr => @dyn_export_records.size, :sql => @sql_text)   
                redirect_to old_url
              when "XLS"
                run_export_xls
              else     
                run_export_csv
            end
          end
        else
          flash[:id]          = dyn_export.id
          flash[:old_url]     = old_url
          flash[:vars]        = vars
          flash[:export_type] = export_type
          redirect_to :action => "export_vars"
        end 
      end
    else
      flash[:error] = id==0 ? "Ce rapport n'existe pas".trn : "Aucun rapport n'existe avec l'id %{id}".trn(:id => id)  
      redirect_to old_url
    end
  end

  def execute_with_vars
    old_url     = params[:old_url]||''
    export_type = params[:export_type]||''
    vars        = params[:select]|| {}
    vars.each do |k,v|
      detail = DynExportDetail.find_by_id(k.to_i)
            
      if detail
        par = (detail.params||'').split('|')
        unless v=='[ALL]'
          vars[k] = detail.argument.gsub('??',v)
          vars[k] = '[ALL]' if (par[0]||'')=='date' && v.blank?
          vars[k] = "%#{vars[k]}%" if ["LIKE","NOT LIKE"].include?(detail.operator) && detail.argument.index('%').nil?
        end             
      end
    end
    redirect_to :action => "execute", :id => params[:id], :old_url => old_url, :vars => vars, :export_type => export_type
  end

  def export_vars
    @dyn_export   = DynExport.find_by_id(flash[:id])
    @old_url      = flash[:old_url]||''
    @vars         = flash[:vars] || ''
    @export_type  = flash[:export_type]
  end

  def details
    old_url = request.env["HTTP_REFERER"]
    @dyn_export = DynExport.find_by_id(params[:id])
    if @dyn_export.active == 'N'
      flash[:error] = "Le rapport '%{report_name}' n'est pas activé".trn(:report_name => @dyn_export.report_name)  
      redirect_to old_url
    end
  end

  def activate_detail
    detail = DynExportDetail.find_by_id(params[:id])
    detail.update_attribute("active",detail.active=='Y' ? 'N' : 'Y') 
    
    respond_to do |format|
      format.html {redirect_to :action => "details", :id => detail.dyn_export.id} 
      format.js do
        params[:id] = detail.dyn_export.id
        details
        @element_id, @partial = ['details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

  def destroy_all
    export = DynExport.find_by_id(params[:id])
    export.dyn_export_details.destroy_all
    export.destroy
    redirect_to :action => "list"
  end

  def destroy_detail
    detail = DynExportDetail.find_by_id(params[:id])
    detail.update_attribute("sequence",99999) 
    detail.compress_sequence({:clause => detail.clause})
    detail.destroy 
    
    respond_to do |format|
      format.html {redirect_to :action => "details", :id => detail.dyn_export.id} 
      format.js do
        params[:id] = detail.dyn_export.id
        details
        @element_id, @partial = ['details_table_div','details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_table','details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

  def save_table
    export = DynExport.find_by_id(params[:id])
    table = params[:query].present? && params[:query][:table].present? ? params[:query][:table] : ""
    if table.blank?
      flash[:error] = "Sélectionnez un nom de table".trn  
    elsif !export.valid_table(table)
      flash[:error] = "La table '%{table}' n'est pas un modèle Rails".trn(:table => table)  
    else  
      detail = export.dyn_export_details.first(:conditions => {:clause => "TABLE"})
      if detail
        detail.update_attribute('name',table)
      else
        export.dyn_export_details << DynExportDetail.new({:clause => "TABLE", :sequence => 1, :name => table, :active => 'Y'})
      end
    end
    redirect_to :action => "details", :id => params[:id]
  end

  def save_wheres
    export = DynExport.find_by_id(params[:id])
    if export && params[:where].present? && (params[:where][:operator].present? || params[:where][:value].present?)       
      i = -1
      export.dyn_export_details.all(:order => "sequence asc", :conditions => {:clause => "WHERE"}).each do |d|
        if d.active == 'Y'
          i += 1
          d.update_attributes({:operator => params[:where][:operator].present? ? params[:where][:operator][i] : '',:argument => params[:where][:value][i],:params => params[:where][:params][i]})
        end
      end
    end
    respond_to do |format|
      format.html {redirect_to :action => "details", :id => params[:id]} 
      format.js do
        details
        @element_id, @partial = 'details_where_div', 'details_where'
        render 'shared/replace_content'
      end
    end
  end    
  
  def save_fields
    export = DynExport.find_by_id(params[:id])
    if export && params[:fields].present? && params[:fields][:label].present? 
      i = -1
      export.dyn_export_details.all(:order => "sequence asc", :conditions => {:clause => "FIELDS"}).each do |d|
        if d.active == 'Y'
          i += 1
          d.update_attribute("operator",params[:fields][:label][i])
        end
      end
    end

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => params[:id]} 
      format.js do
        details
        @element_id, @partial = 'details_fields_div', 'details_fields'
        render 'shared/replace_content'
      end
    end
  end

  def move_down
    detail = DynExportDetail.find_by_id(params[:id])
    detail.update_attribute("sequence",detail.sequence + 1.5) 
    detail.compress_sequence({:clause => detail.clause})

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => detail.dyn_export.id} 
      format.js do
        params[:id]=detail.dyn_export.id
        details
        case detail.clause
          when "FIELDS"
            @element_id, @partial = 'details_fields_div', 'details_fields'
          when "WHERE"
            @element_id, @partial = 'details_where_div', 'details_where'
          when "SORT"
            @element_id, @partial = 'details_sort_div', 'details_sort'
        end
        render 'shared/replace_content'
      end
    end
  end
    
  def move_up
    detail = DynExportDetail.find_by_id(params[:id])
    detail.update_attribute("sequence",detail.sequence - 1.5) 
    detail.compress_sequence({:clause => detail.clause})

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => detail.dyn_export.id} 
      format.js do
        params[:id]=detail.dyn_export.id
        details
        case detail.clause
          when "FIELDS"
            @element_id, @partial = 'details_fields_div', 'details_fields'
          when "WHERE"
            @element_id, @partial = 'details_where_div', 'details_where'
          when "SORT"
            @element_id, @partial = 'details_sort_div', 'details_sort'
        end
        render 'shared/replace_content'
      end
    end
  end

  def change_order
    detail = DynExportDetail.find_by_id(params[:id])
    detail.update_attribute("operator",detail.operator == 'ASC' ? 'DESC' : 'ASC')        

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => detail.dyn_export.id} 
      format.js do
        params[:id]=detail.dyn_export.id
        details
        @element_id, @partial = 'details_sort_div', 'details_sort'
        render 'shared/replace_content'
      end
    end
  end

  def add_sort_fields
    export = DynExport.find_by_id(params[:id])
    field_list = params[:sort][:fields] - ['']    
    flash[:error] = 'Sélectionnez un champs.'.trn if !params[:sort].present? || field_list.empty?
    tmp_order = !params[:sort].present? || params[:sort][:order].presence.blank? ? 'ASC' : params[:sort][:order]
    field_list.each_with_index do |f,i|
      export.dyn_export_details << DynExportDetail.new({:clause => "SORT", :sequence => 9999 + i, :name => f, :operator => tmp_order, :active => 'Y'})
    end if params[:sort].present? && !params[:sort][:order].presence.blank?  
    export.compress_sequence({:clause => "SORT"})

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => export.id} 
      format.js do
        details
        @element_id, @partial = ['details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

  def add_include_clause
    export = DynExport.find_by_id(params[:id])
#    link_list = params[:include][:tables] - ['']    
    link_list = params[:include].present? && params[:include][:tables].present? ? [params[:include][:tables]] : []    
    flash[:error] = 'Sélectionnez un lien.'.trn if !params[:include].present? || link_list.empty? 
    link_list.each_with_index do |l,i|
      export.dyn_export_details << DynExportDetail.new({:clause => "INCLUDE", :sequence => 9999 + i, :name => l.split(';').last, :operator => l.split(';').first, :active => 'Y'})
    end if params[:include].present?  
    export.compress_sequence({:clause => "INCLUDE"})
    
    respond_to do |format|
      format.html {redirect_to :action => "details", :id => export.id} 
      format.js do
        details
        @element_id, @partial = ['details_table_div','details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_table','details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

  def save_where_string
    export = DynExport.find_by_id(params[:id])
    where_string = params[:where][:string]||''    

    detail = export.dyn_export_details.first(:conditions => {:clause => "WHERE_STRING"})
    if detail
      detail.update_attribute('argument',where_string)
    else
      export.dyn_export_details << DynExportDetail.new({:clause => "WHERE_STRING", :sequence => 1, :argument => where_string, :active => 'Y'})
    end

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => export.id} 
      format.js do
        details
        @element_id, @partial = 'details_where_div', 'details_where'
        render 'shared/replace_content'
      end
    end
  end


  def add_empty_where_clause
    export = DynExport.find_by_id(params[:id])
    export.dyn_export_details << DynExportDetail.new({:clause => "WHERE", :sequence => 9999, :name => "", :operator => "", :argument => 'Free condition here', :active => 'Y'})
    export.compress_sequence({:clause => "WHERE"})    

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => export.id} 
      format.js do
        details
        @element_id, @partial = ['details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

  def add_where_clause
    export = DynExport.find_by_id(params[:id])
    field_list = params[:where][:fields] - ['']    
    flash[:error] = 'Sélectionnez un champs.'.trn if !params[:where].present? || field_list.empty? 
    field_list.each_with_index do |f,i|
      export.dyn_export_details << DynExportDetail.new({:clause => "WHERE", :sequence => 9999 + i, :name => f, :operator => '=', :argument => 'enter your value here', :active => 'Y'})
    end if params[:where].present?  
    export.compress_sequence({:clause => "WHERE"})    

    respond_to do |format|
      format.html {redirect_to :action => "details", :id => export.id} 
      format.js do
        details
        @element_id, @partial = ['details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

  def add_select_fields    
    export = DynExport.find_by_id(params[:id])
    field_list = params[:select][:fields] - ['']    
    flash[:error] = 'Sélectionnez un champs.'.trn if !params[:select].present? || field_list.empty? 
    field_list.each_with_index do |f,i|
      export.dyn_export_details << DynExportDetail.new({:clause => "FIELDS", :sequence => 9999 + i, :name => f, :operator => f.gsub('.',' ').humanize, :active => 'Y'})
    end if params[:select].present?  
    export.compress_sequence({:clause => "FIELDS"})
    
    respond_to do |format|
      format.html {redirect_to :action => "details", :id => export.id} 
      format.js do
        details
        @element_id, @partial = ['details_include_div','details_fields_div','details_where_div','details_sort_div'], ['details_include','details_fields','details_where','details_sort']
        render 'shared/replace_content'
      end
    end
  end

private

  def run_export_xls

    file_name       = "export_#{@dyn_export_table}_#{Time.now.strftime("%Y%m%d%H%M%S").to_s}.xls"
    path            = File.join(Rails.root , 'public', 'archives')    
    full_file_name  = File.join(path , file_name)
    FileUtils.mkdir_p(path) unless File.exist?(path)

    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => @dyn_export_table
    format = Spreadsheet::Format.new :pattern_fg_color => :silver,
                                     :pattern => 1, 
                                     :align => :center,
                                     :size => 11                                     
    sheet1.row(0).default_format = format
    sheet1.row(0).push *@dyn_export_fields.map {|f| f[1]}

    num_line = 0
    @dyn_export_records.each do |r|       
      num_line += 1 
      tab_line=[]
      @dyn_export_fields.each_with_index do |f,i|          
        tab_line << r["field_#{i}"]  
      end        
      sheet1.row(num_line).push *tab_line
    end

    book.write full_file_name
    send_file(full_file_name, { :filename => file_name, :disposition => "attachment" })
  end


  def run_export_csv    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
      csv << @dyn_export_fields.map {|f| f[1]}
      @dyn_export_records.each do |r|        
        tab_line=[]
        @dyn_export_fields.each_with_index do |f,i|          
          tab_line << r["field_#{i}"]  
        end        
        csv << tab_line
      end
    end
    filename = "export_#{@dyn_export_table}_#{Time.now.strftime("%Y%m%d%H%M%S").to_s}.csv"
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :type => 'text/csv', :filename => filename
  end

  def execute_query(dyn_export,export_type='IT',vars)
    errors = []
    @dyn_export_table,@dyn_export_fields,wheres,where_string,sorts,includes = get_export_details(dyn_export,export_type,vars)
    errors << "La table n'est pas paramétrée".trn if @dyn_export_table.blank?
    errors << "Aucun champs n'est paramétré".trn if @dyn_export_fields.blank?

    unless @dyn_export_table.blank? 
      @dyn_export_table = @dyn_export_table.downcase    
      unless (table_model = dyn_export.valid_table(@dyn_export_table))
        errors << "Le modèle '%{modele}' n'existe pas".trn(:modele => @dyn_export_table.classify)    
      end
    end    
    
    
    if errors.empty?
      error, @dyn_export_records = get_record(@dyn_export_fields.map {|f| f[0]},table_model, wheres,where_string, sorts, includes)
      errors << error unless error.blank?    
    end
    return errors
  end

  def get_record(select,table_model, wheres, where_string, sorts, includes)
    error = ''    
    conditions = DynExport.build_condition(wheres,where_string)
    order      = sorts
    begin
      conditions = conditions[0] if conditions.size == 1
      sql_text = table_model.joins(includes).where(conditions).order(order).select(select).to_sql
      @sql_text = sql_text 
      records = table_model.find_by_sql(sql_text) #(:all,:order => order, :conditions => conditions, :include => includes)
    rescue Exception => e    
      records = nil
      if Rails.env.upcase == "DEVELOPMENT"
        tmp_err = "Erreur d'exportation ou de SQL : '%{err}'".trn(:err => e.message)
        logger.fatal tmp_err        
        error   = tmp_err
      else
        error   = "Pourriez vous corriger la condition de l'extraction dynamique ? Regardez le fichier log pour plus d'information.".trn
      end    
    end
    return error, records
  end


  def get_export_details(dyn_export,export_type='IT',vars)
    table         = dyn_export.get_table
    fields        = dyn_export.get_fields(export_type)
    wheres        = dyn_export.get_where(vars)
    where_string  = dyn_export.get_where_string
    sorts         = dyn_export.get_sort
    includes      = dyn_export.get_includes    
    return table,fields,wheres,where_string,sorts,includes
  end

end
