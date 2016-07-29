# encoding: UTF-8
class DynExport < ActiveRecord::Base

  has_es_interface_models
  
  has_many :dyn_export_details

  acts_as_dynamic_model([
                     { :name              => "code",
                       :column_name       => "Code".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false,
                       :search            => false,
                       :order_load        => 1,
                       :field_key         => true,
                       :upper_case        => true,
                       :mandatory         => true
                      },
                     { :name              => "name",
                       :link_show         => false,
                       :link_update       => false,
                       :column_name       => "Nom".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false,
                       :search            => false,
                       :mandatory         => true,
                       :order_load        => 2
                      },
                     { :name              => "description",
                       :column_name       => "Description".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false,
                       :order_load        => 3
                      },
                     { :name              => "active",
                       :column_name       => "Activé".trn,
                       :dynamic_filter    => false,
                       :dynamic_search    => false
                      }
                      ],{
                        :audit_model=>false,
                        :delete_if_inactive => true
                        }
                      )


  acts_as_audited :keep_text          => true,
                  :model_audit_label  => "Dynamic export".trn,
                  :process_label      => "Manual change".trn

  def get_audit_label
    self.code 
  end

  def report_name
    self.name||self.code
  end

  def self.valid_table(table_name)
      table_name = table_name.downcase    
      begin
        table_model = table_name.classify.constantize
        return table_model
      rescue  
        return false   
      end
  end

  def valid_table(table_name)
    self.class.valid_table(table_name)
  end

  def not_available_link(table_name)
    self.get_includes_setup(table_name.singularize)
  end

  def available_links(table_name="")
    table_names = [table_name.blank? ? get_table.singularize : table_name]
    
    includes_setup = self.get_includes_setup('',['Y','N'])
    includes_setup.each do |is|
      table_names << is[1].singularize
    end
    
    tmp_tables = []
    table_names.uniq.each do |t|
      tmp_tables += DynExport.get_table_linked(t)
    end
    tmp_result = (tmp_tables - includes_setup)
    tmp_result.reject! {|t| table_names.include?(t[1].singularize)}
    return tmp_result.map{|t| ["#{t[0]} ==> #{t[1]}","#{t[0]};#{t[1]}"]}
  end

  def self.get_table_linked(table_name)
    tmp_tables = []
    if (table_model = self.valid_table(table_name))
      table_model.reflect_on_all_associations.each do |elem|
        case elem.macro.to_s
        when "has_many", "has_and_belongs_to_many"
          table = elem.name.to_s.tableize.upcase
        when "belongs_to", "has_one"
          table = elem.name.to_s.tableize.singularize.upcase
        end
        tmp_tables << [table_name,table] if self.valid_table(table.singularize)
      end
    end 
    return tmp_tables   
  end

  def change_table_available?
    get_fields.blank? && get_where.blank? && get_sort.blank? && get_includes.blank?
  end
  
  def get_table
    detail = self.dyn_export_details.find(:first, :conditions => {:clause => "TABLE", :active => 'Y'}, :order => "sequence asc")
    table = detail ? detail.name : "" 
  end
     
  def get_fields(export_type='IT')
    details = self.dyn_export_details.find(:all, :conditions => {:clause => "FIELDS", :active => 'Y'}, :order => "sequence asc")
    fields = []
    details.each_with_index do |f,i|
      field_name = f.name.downcase
      fields << ["#{field_name} as field_#{i}", (['IT','SQL'].include?(export_type) || f.operator.blank?) ? field_name : f.operator, f.argument.blank? ? "" : f.argument]
    end
    fields 
  end

  def get_sort
    details = self.dyn_export_details.find(:all, :conditions => {:clause => "SORT", :active => 'Y'}, :order => "sequence asc")
    sort_array = []
    details.each do |f|
      field_name = f.name.downcase
      operator   = f.operator.downcase == 'desc' ? 'desc' : ''
      sort_array << "#{field_name} #{operator}".strip
    end
    sort_array.join(',')
  end

  def get_where_string
    details = self.dyn_export_details.find(:first, :conditions => {:clause => "WHERE_STRING", :active => 'Y'})
    return details ? details.argument : ''
  end

  def get_where(vars={})
    vars = {} if vars.blank?
    string = get_where_string
    details = self.dyn_export_details.find(:all, :conditions => {:clause => "WHERE", :active => 'Y'}, :order => "sequence asc")
    wheres = []
    details.each do |f|
      field_name = (f.name||'').downcase  
      wheres << [field_name, field_name.blank? ? '' : (f.operator || '='), f.argument,f.id] 
    end

    wheres.each do |w|
      w[2]=vars[w[3].to_s] if vars[w[3].to_s].present?
    end

    wheres.map! do |w|
      if !string.blank? && w[2]=='[ALL]'
        [1, '=', 1,w[3]] 
      else
        w
      end
    end

    wheres.reject!{|w| w[2]=='[ALL]'}

    wheres
  end

  def self.build_condition(wheres,where_string)
    if where_string.blank?
      conditions = ['']    
      wheres.each do |w|
        if w[0].blank? && w[1].blank?
          unless w[2].blank?
            conditions[0] += conditions[0].blank? ? '' : ' AND ' 
            conditions[0] += "(#{w[2]})"
          end 
        else
          conditions[0] += conditions[0].blank? ? '' : ' AND ' 
          conditions[0] += "( #{w[0]} #{w[1]} #{w[2].nil? ? '' : '?'})" 
          conditions << w[2] unless w[2].nil? 
        end
      end  
    else
      conditions = [where_string.gsub('%{','%{cond_')]
      cond_hash  = {}
      wheres.each_with_index do |w,i|
        if w[0].blank? && w[1].blank?
          cond_hash["cond_#{i+1}".to_sym] = w[2] unless w[2].blank?  
        else
          conditions << w[2] unless w[2].nil?
          cond_hash["cond_#{i+1}".to_sym] = "#{w[0]} #{w[1]} #{w[2].nil? ? '' : '?'}"  
        end
      end  
      begin
        conditions[0] = conditions[0] % cond_hash  
      rescue  
        conditions[0] = "Condition error"
      end
    end    
    conditions
  end

  def get_where_var
    details = self.dyn_export_details.find(:all, :conditions => {:clause => "WHERE", :active => 'Y'}, :order => "sequence asc")
    wheres_var = []
    details.each do |f|
      field_name = (f.name||'').downcase           
      unless f.argument.index('??').nil?
        arg = (f.params||"").split('|')        
        wheres_var << [f.id,arg[1]||f.name.gsub('.',' ').humanize,arg[0]||"string", (arg[2]||'').split(','),f.argument]        
      end           
    end
    wheres_var
  end

  def get_includes_setup(table_name='',active=['Y'])
    details = self.dyn_export_details.find(:all, :conditions => {:clause => "INCLUDE", :active => active}, :order => "sequence asc")
    includes = []
    details.each do |i|
      if ['',i.operator.singularize].include?(table_name) 
        includes << [i.operator,i.name] #from,to
      end
    end
    includes
  end

  def get_includes
    get_include_for(self.get_table.singularize)
  end

  def get_include_for(table_name,type="A")
    details = self.dyn_export_details.find(:all, :conditions => {:clause => "INCLUDE", :operator => table_name, :active => 'Y'}, :order => "sequence asc")
    includes = type=='A' ? [] : {}
    details.each do |i|      
      sub_include = get_include_for(i.name.singularize,"H")
      include_name = i.name.downcase            
      if type=='A'
        includes << (sub_include.blank? ? include_name.to_sym : {include_name.to_sym => sub_include}) 
      else
        includes[include_name.to_sym] = sub_include.blank? ? {} : sub_include 
      end
    end    
    return includes
  end
      
  def last_sequence(clause)
    self.dyn_export_details.find(:all,:conditions => {:clause => clause}, :order => "sequence asc").size
  end 

  def get_tables
    main_table = self.get_table
    tables = main_table.blank? ? [] : [main_table]
    self.get_includes_setup.each do |t|
      tables << t[1].downcase.pluralize.upcase   
    end
    tables
  end


  def compress_sequence(condition={})
    tmp_dyn_export = self.dyn_export_details
    elements = tmp_dyn_export.find(:all,:conditions=> condition, :order => "sequence asc")
    elements.each_with_index do |e,i|
      e.update_attribute('sequence', i+1)
    end
  end   

   
  def available_field(clause,all_field=false)
    fields = []    
    self.get_tables.each do |t|      
      fields += t.downcase.classify.constantize.column_names.map {|f| "#{t}.#{f.upcase}"} if self.valid_table(t)
    end
    if all_field
      fields_not_available = []
    else
      fields_not_available = self.dyn_export_details.find(:all,:conditions => {:clause => clause}).map{|f| f.name}
    end
    (fields - fields_not_available).sort
  end
     
  def not_available_field(clause,table_name='')
    conditions = ["clause = ?",clause]
    unless table_name.blank?
      table_name = table_name.singularize.pluralize.upcase
      conditions[0] += " AND name LIKE ?"
      conditions << "#{table_name}.%"
    end          
    fields_not_available = self.dyn_export_details.find(:all,:conditions => conditions).map{|f| f.name}
    fields_not_available.sort
  end
     
end
