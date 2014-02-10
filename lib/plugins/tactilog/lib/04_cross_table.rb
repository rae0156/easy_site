# ActAsActiveModel
module CrossTable
  require 'fileutils'  
  require 'yaml'

  RAILS_ROOT  = "#{Rails.root}" unless defined?(ROOT_PATH)
  SETUP_FILE_NAME = File.join(RAILS_ROOT,'config','cross_table.yml')

  

  
  def self.included(base)
     base.send :extend , ClassMethods
     base.send :include, InstanceMethods
  end 


  module ClassMethods    
    def cross_table(options = {})
      if options.inspect == ":help" || options.inspect == '"help"'
        CrossTable.analyse_cross_table("help")
      else  
        CrossTable.analyse_cross_table(self,options)
      end
    end 
    
  end
  
  module InstanceMethods
        
    def cross_table(options = {})
      if options.inspect == ":help" || options.inspect == '"help"'
        CrossTable.analyse_cross_table("help")
      else  
        CrossTable.analyse_cross_table(self,options)
      end
    end 
  end


private 
  
  
  def self.analyse_cross_table(recordset,options = {})
    
    tmp_text = ""
    if recordset == "help" then
         tmp_text = help_text      
    elsif recordset.nil? then
         tmp_text = "A parameter NIL is not available."
         tmp_text += "\n\n\n" + help_text
    else
      if recordset.class.superclass.to_s == "ActiveRecord::Base" or recordset.class.ancestors.include?(ActiveRecord::Base) then
        options[:root] = recordset.class.to_s.downcase if options.empty? || (!options.has_key?(:root) && !options.has_key?(:setup))  
        options[:format] = "text" if options.empty? || (!options.has_key?(:format))  
        options[:level] = "5" unless !options.blank? && options.has_key?(:level) && is_numeric?(options[:level])
        tmp_text = debug_field_analyse(recordset,options)
        tmp_text += "\n" + recordset.class.cross_table if options.has_key?(:class) && options[:class] == true  
      elsif recordset.class.to_s == "Class" && (recordset.superclass.to_s == "ActiveRecord::Base" or recordset.ancestors.include?(ActiveRecord::Base))  then   
         options[:level] = "5" unless !options.blank? && options.has_key?(:level) && is_numeric?(options[:level])
         tmp_text = debug_skeleton(recordset,options)
         add_setup(recordset.to_s.downcase,tmp_text) if !options[:filter].empty? && (options.has_key?(:setup_file) && options[:setup_file] == true)

      else
         tmp_text = "This class '#{recordset.class}' is not available"
         tmp_text += "\n\n\n" + help_text
      end    
    end
    tmp_text
  end
  
  def self.add_setup(name,contain)
    rails_env = (ENV['RAILS_VERSION'].blank? ? Rails::VERSION::STRING : ENV['RAILS_VERSION'])[0]    

    setup_cross_table = {}
    if File.exist?(SETUP_FILE_NAME)     

      tmp_hash = {}
      if rails_env == '3'
        YAML::load_documents( File.open(SETUP_FILE_NAME) ) do |doc|
          tmp_hash.merge!(doc) if doc.is_a?(Hash)
        end
      else
        tmp_docs = YAML::load_stream( File.open(SETUP_FILE_NAME) )
        tmp_docs.documents.each do |doc|
          tmp_hash.merge!(doc) if doc.is_a?(Hash)
        end
      end
      setup_cross_table=tmp_hash
    end


    File.open(SETUP_FILE_NAME, 'a') do |file|
      file.puts contain
    end unless setup_cross_table.has_key?(name)

  end
  
  
  
  def self.debug_skeleton(recordset,options = {})
    tmp_text = ""

    options[:filter] = "all" if options[:filter].blank?

    options[:indent] = 0 if !options.has_key?(:indent)
    options[:type] = "" if !options.has_key?(:type)
    options[:done] = [] if !options.has_key?(:done)
    options[:filter] = [] if !options.has_key?(:filter)
    options[:level_done] ||= "1" 
    
    
    
    options[:title_class] = recordset.to_s.downcase if !options.has_key?(:title_class)
    
    tmp_generator = !options[:filter].empty? && (options.has_key?(:show_setup) && options[:show_setup] == true || options.has_key?(:setup_file) && options[:setup_file] == true)
    
    tmp_indent = options[:indent] || 0    
    if tmp_generator then
      text_indent = (" " * (8 * tmp_indent))
      tmp_text += "\n" + text_indent + "#{options[:title_class]}:"    
    else
      text_indent = (" " * (4 * tmp_indent))
      tmp_text += "\n" + text_indent + "#{recordset.to_s.humanize}"    
      tmp_text += " (#{options[:type]})" unless options[:type] == ""
    end

    
    options[:done] = options[:done] << recordset.to_s 

    if tmp_generator then
      tmp_link_tab = []
      #tmp_link_class_tab = []
      recordset.reflect_on_all_associations.each do |elem|
        begin
          tmp_class = recordset.reflect_on_association(elem.name).klass
        rescue
          tmp_class = nil
        end
        
        unless tmp_class.nil? then       
          if !options[:done].include?(tmp_class.to_s) && (options[:filter].empty? || options[:filter].include?(tmp_class.to_s) || options[:filter].include?('all'))
            tmp_link_tab << elem.name.to_s   
            #tmp_link_class_tab << tmp_class.to_s   
          end
        end
      end
      
#      options[:filter] = tmp_link_class_tab if options[:filter].include?('all')

      if recordset.columns.map(&:name).include?('id')  
        tmp_text += "\n" + text_indent + '    order: "' + recordset.table_name + '.id ASC"'
      else
        tmp_text += "\n" + text_indent + '    order: ""'
      end          
      tmp_text += "\n" + text_indent + '    fields_line: [""]'
      tmp_text += "\n" + text_indent + '    fields_line_extend: [""]'
      tmp_text += "\n" + text_indent + '    fields_excluded: [""]'
      tmp_text += "\n" + text_indent + '    deactivate_field: [""]'
      tmp_text += "\n" + text_indent + '    no_detail: false'
      tmp_text += "\n" + text_indent + '    detail_field:'
      tmp_text += "\n" + text_indent + '        no_string_field: true'
      tmp_text += "\n" + text_indent + '        nill_field: true'
      tmp_text += "\n" + text_indent + '        all_type_field: true'
      tmp_text += "\n" + text_indent + '    show_relation: false'
      unless tmp_link_tab.empty?
        tmp_text += "\n" + text_indent + '    relations:'
        tmp_text += "\n" + text_indent + '        relation_order: ' + tmp_link_tab.inspect
      end      
    end

    recordset.reflect_on_all_associations.each do |elem|
      
      options[:indent] = tmp_indent + 1
      options[:type] = elem.macro.to_s
      
      begin
        tmp_class = recordset.reflect_on_association(elem.name).klass
      rescue
        tmp_class = nil
      end    
      
      unless tmp_class.nil?        
        if !options[:done].include?(tmp_class.to_s) && (options[:filter].empty? || options[:filter].include?(tmp_class.to_s) || options[:filter].include?("all")) then        
          if options[:level_done].to_i <= options[:level].to_i then
            options[:level_done] = options[:level_done].to_i + 1  
            if tmp_generator then
              options[:title_class] = elem.name.to_s
              tmp_text += debug_skeleton(tmp_class, options)
            else
              tmp_text += debug_skeleton(tmp_class, options)
            end
            options[:level_done] = options[:level_done].to_i - 1  
#          else
#            tmp_text += "\n" + text_indent + "Detail level reaches : [#{tmp_class}]" 
          end
        elsif options[:done].include?(tmp_class.to_s)
#          tmp_text += "\n" + text_indent + "    #{tmp_class.to_s} ===> already crossed" unless tmp_generator
          tmp_text += ""
        else
          unless tmp_generator
            tmp_text += "\n" + text_indent + "    #{tmp_class.to_s}"
            tmp_text += "   (#{elem.name.to_s})" if elem.options.has_key?(:class_name)
          end          
        end
      end    
    end
    
    options[:done].pop
    tmp_text
  end
  
  def self.debug_export_field(recordset,options = {})
    options.symbolize_keys!
    
    unless options[:detail_field].nil?
      options[:detail_field].symbolize_keys! 
      tmp_no_string_field = to_bool(options[:detail_field][:no_string_field]) || false
      tmp_nil_field = to_bool(options[:detail_field][:nill_field]) || false
      tmp_all_type_field = to_bool(options[:detail_field][:all_type_field]) || false
    else
      tmp_no_string_field = true
      tmp_nil_field = true
      tmp_all_type_field = true
    end
    tmp_format = options[:format].to_s
    tmp_deactivate_field = options[:deactivate_field].to_s || ""
    tmp_no_detail = to_bool(options[:no_detail]) || false
    
    tmp_multiple = to_bool(options[:multiple]) || false
    tmp_show_relation = to_bool(options[:show_relation]) || false
    tmp_table_title = options[:table_title] || ""
    tmp_indent = options[:indent] || 0
    text_indent_title = (" " * (4 * tmp_indent))  
    text_indent = (" " * (4 * (tmp_indent + 1)))
    tmp_text = ""
    
    tmp_max_column_name_size = 0
    for column in recordset.class.content_columns
      tmp_max_column_name_size = [column.name.humanize.length,tmp_max_column_name_size].max
    end

    tab_field = Array.new
    for column in recordset.class.columns
      tab_field << column.name
    end


    tab_field.include?(tmp_deactivate_field) ? tmp_deactivate = (recordset.send(tmp_deactivate_field) != "Y") : tmp_deactivate = false
    
    tmp_fields_line = ["id"]
    if options[:fields_line].nil?
      tmp_fields_line << "name"
    else
      tmp_fields_line.concat(options[:fields_line].to_a)
    end

    unless options[:fields_line_extend].nil?
      tmp_fields_line_extend = options[:fields_line_extend].to_a
    else
      tmp_fields_line_extend = []
    end    

    unless options[:fields_excluded].nil?
      tmp_fields_excluded = options[:fields_excluded].to_a
    else
      tmp_fields_excluded = []
    end    

    if tmp_format=='fixture'
      tmp_text += "\n"
    else
      tmp_text += "\n" + text_indent_title
    end    
    
    if ["fixture","YMLID", "YML"].include?(tmp_format)
      if tmp_multiple || ["fixture","YMLID"].include?(tmp_format)
        tmp_text += "#{recordset.class}_#{recordset.id.to_i}:"
      elsif 
        tmp_text += "#{recordset.class}:"
      end
    else
      if recordset.class.to_s.classify == tmp_table_title.classify || tmp_table_title == "" then
        tmp_text += "#{recordset.class.to_s} :"
      else
        tmp_text += "#{tmp_table_title.humanize} (#{recordset.class.to_s}) :"      
      end
      tmp_fields_line.each do |tmp_field_line|
        tmp_text += " #{recordset.send(tmp_field_line)}" if tab_field.include?(tmp_field_line)        
      end

      unless tmp_fields_line_extend.empty?
        i = 0
        tmp_fields_line_extend.each do |tmp_field_line_extend|     
          if tab_field.include?(tmp_field_line_extend) && !tmp_fields_line.include?(tmp_field_line_extend)
            i += 1          
            tmp_text += " (" if i == 1
            tmp_text += " #{recordset.send(tmp_field_line_extend)} "
          end        
        end       
        tmp_text += ")" unless i==0        
      end
      
      tmp_text += " deactivated" if tmp_deactivate

    end
       
    if tmp_format=="YML" || tmp_format=='YMLID'
      tmp_text += "\n" + text_indent + "id: #{recordset.id}"      if tmp_format=="YML" && recordset.class.columns.map(&:name).include?('id')
      for column in recordset.class.content_columns
        if recordset.send(column.name).blank?
          tmp_text += "\n" + text_indent + column.name+ ':'
        else
          case column.type.to_s
            when "string"
              if recordset.send(column.name) != "N" || tmp_no_string_field == true 
                tmp_text += "\n" + text_indent + column.name+ ': "' + recordset.send(column.name).to_s + '"'
              end              
            when "decimal","integer"
                tmp_text += "\n" + text_indent + "#{column.name}: #{recordset.send(column.name)}"
            when "date"
                tmp_text += "\n" + text_indent + "#{column.name}: #{recordset.send(column.name).strftime('%Y-%m-%d')}"
            when "datetime"
                tmp_text += "\n" + text_indent + "#{column.name}: #{recordset.send(column.name).strftime('%Y-%m-%d %H:%M:%S')}"
            else              
                tmp_text += "\n" + text_indent + "#{column.name}: #{recordset.send(column.name)}"
          end
        end
      end
    elsif tmp_format=="fixture"
      for column in recordset.class.columns.select{ |c| c.name =~ /(_id|_count)$/ }  # c.name == "id" || 
        tmp_text += "\n" + "    " + "#{column.name}: "

        unless recordset.send(column.name).nil?
          tmp_text += "<%= Fixtures.identify(:#{column.name[0..-4].classify}_" if column.name =~ /(_id)$/
          tmp_text += "#{recordset.send(column.name).to_i}"
          tmp_text += ") %>" if column.name =~ /(_id)$/
        end        
      end

      for column in recordset.class.content_columns
        tmp_text += "\n" + "    " + "#{column.name}: "
        unless recordset.send(column.name).blank?
          case column.type.to_s
            when "string"
                tmp_text += '"' + recordset.send(column.name).to_s + '"'
            when "decimal","integer"
                tmp_text += "#{recordset.send(column.name)}"
            when "date"
                tmp_text += "#{recordset.send(column.name).strftime('%Y-%m-%d')}"
            when "datetime"
                tmp_text += "#{recordset.send(column.name).strftime('%Y-%m-%d %H:%M:%S')}"
            else              
                tmp_text += "#{recordset.send(column.name)}"
          end
        end        
      end
      
      tmp_text += "\n"      
    else
      unless tmp_no_detail or tmp_deactivate
        for column in recordset.class.content_columns        
          tmp_column_name = column.name.humanize + (" " * (tmp_max_column_name_size - column.name.humanize.length))
          if !tmp_fields_line.include?(column.name) && !tmp_fields_line_extend.include?(column.name) && !tmp_fields_excluded.include?(column.name)
            if !recordset.send(column.name).nil? || tmp_nil_field == true
              case column.type.to_s
                when "string"
                  if recordset.send(column.name) != "N" || tmp_no_string_field == true 
                    tmp_text += "\n" + text_indent + "#{tmp_column_name} : #{recordset.send(column.name)}"
                  end              
                when "date","decimal","integer"
                    tmp_text += "\n" + text_indent + "#{tmp_column_name} : #{recordset.send(column.name)}"
                else              
                    tmp_text += "\n" + text_indent + "#{tmp_column_name} : #{recordset.send(column.name)} (#{column.type.to_s})" if tmp_all_type_field == true
              end
            end
          end
        end
      end
    end

     

    if tmp_show_relation && tmp_format=="text" then        
      tmp_text += "\n" + text_indent + "Relations :"
      tmp_text += debug_export_relation(recordset, "[all]", tmp_indent + 1, nil)
    end    
    
    tmp_text
  end

  def self.debug_field_analyse(recordset,param_setup = {})
    tmp_text = ""
    param_setup.symbolize_keys!

#    #--------------------------
#    tmp_text += debug_hash(param_setup[:setup])
#    #--------------------------
    
    tmp_format = param_setup[:format].blank? ? "text" : param_setup[:format] 
    tmp_level = param_setup[:level] 
    tmp_level_done = param_setup[:level_done] || "1" 
    
    unless param_setup[:root].nil?
      tmp_root_element = param_setup[:root]
      param_setup = read_debug_field_file(tmp_root_element)
      param_setup[:format] = tmp_format
      param_setup[:level] = tmp_level 
    end
    
    if param_setup[:error_message].nil? || param_setup[:error_message] == "" then
      if param_setup[:setup]
        param_setup[:setup].symbolize_keys!

        tmp_indent = param_setup[:indent] || 0
        tmp_table_title = param_setup[:table_title] || ""
        text_indent_title = (" " * (4 * tmp_indent))  
        text_indent = (" " * (4 * (tmp_indent + 1)))  

        tmp_is_relations = param_setup[:setup].has_key?(:relations) && tmp_level_done.to_i <= param_setup[:level].to_i
        if recordset.nil? then
          if tmp_indent == 0 then
            tmp_text += "\n" + text_indent_title + "Please chose another element"
            tmp_text += " for '#{tmp_root_element}'" unless tmp_root_element.nil?             
          end
        else
            if tmp_is_relations then
              tmp_relation = param_setup[:setup][:relations] 
              tmp_relation.symbolize_keys!
              tmp_relation[:format] = tmp_format
              tmp_relation[:level] = param_setup[:level]
              tmp_relation[:level_done]=tmp_level_done
            end
            
            if tmp_is_relations && !tmp_relation[:relation_order_before].nil? && tmp_format == 'text' then
              tmp_relation[:relation_order_before].each do |tmp_element|
                tmp_text += debug_export_relation(recordset, tmp_element, tmp_indent - 1, tmp_relation)
              end
            end
            
            if tmp_level_done.to_i <= param_setup[:level].to_i
              tmp_param_for_export_field = {}
              tmp_param_for_export_field.update(param_setup[:setup])            
              tmp_param_for_export_field[:multiple] = param_setup[:multiple]
              tmp_param_for_export_field[:indent] = tmp_indent
              tmp_param_for_export_field[:table_title] = tmp_table_title
              tmp_param_for_export_field[:format] = tmp_format
  
              tmp_text += debug_export_field(recordset,tmp_param_for_export_field)
            else
              tmp_text += "\n" + text_indent_title + "Detail level reaches : [#{recordset.class}]" 
            end            
            
            if tmp_is_relations then
              tmp_relation[:relation_order].each do |tmp_element|              
                tmp_text += debug_export_relation(recordset, tmp_element, tmp_indent, tmp_relation)
              end
            end
            
        end        
      end
    else
      tmp_text = "An error occured during the YML loading file :" + "\n" + param_setup[:error_message] 
    end
    
    tmp_text
  end

  def self.debug_export_relation(recordset, tmp_element, tmp_indent, tmp_relation)
    tmp_text = ""
    text_indent_title = (" " * (4 * tmp_indent))  
    text_indent = (" " * (4 * (tmp_indent + 1)))  
    tmp_format = tmp_relation[:format].to_s || "text" 
    tmp_level = tmp_relation[:level].to_s || "0" 
    tmp_level_done=tmp_relation[:level_done] || "0"

    recordset.class.reflect_on_all_associations.each do |elem|
      if tmp_element == elem.name.to_s || tmp_element == "[all]"
        unless tmp_relation.nil?
          tmp_setup_child = {}
          tmp_setup_child.update(tmp_relation[elem.name.to_sym]) unless tmp_relation[elem.name.to_sym].nil?                     
          tmp_setup_child = {:setup => tmp_setup_child}
          tmp_setup_child[:table_title] = elem.name.to_s
          tmp_setup_child[:format] = tmp_format
          tmp_setup_child[:level] = tmp_level
          tmp_setup_child[:level_done]= tmp_level_done.to_i + 1          
          
          case elem.macro.to_s
            when "belongs_to", "has_one"
              tmp_obj = recordset.send(elem.name)
              tmp_setup_child[:indent] = tmp_indent + 1
              unless tmp_obj.blank?
                tmp_text += debug_field_analyse(tmp_obj, tmp_setup_child)
              end              
            when "has_many", "has_and_belongs_to_many"
              unless tmp_relation[elem.name.to_sym].blank?  
                tmp_relation[elem.name.to_sym].symbolize_keys!
                tmp_order = ""
                tmp_order = tmp_relation[elem.name.to_sym][:order] if tmp_relation.has_key?(elem.name.to_sym) && !tmp_relation[elem.name.to_sym].nil? && tmp_relation[elem.name.to_sym].has_key?(:order) 
                
                if tmp_order=="" then
                  tmp_objects = recordset.send(elem.name)
                else
                  tmp_objects = recordset.send(elem.name).find(:all, :order => tmp_order)
                end
              
                tmp_setup_child[:indent] = tmp_indent + 2                      
                tmp_setup_child[:multiple] = "true"                      
    
                unless tmp_objects.empty?
                  if tmp_format=='YML' || tmp_format=='YMLID'
                    tmp_text += "\n" + text_indent + "#{elem.name.to_s}:" 
                  elsif tmp_format=='fixture'
  #                  do nothing 
                  else
                    tmp_text += "\n" + text_indent + "#{elem.name.to_s.humanize}" 
                    tmp_text += " (nbr : #{tmp_objects.length})" if tmp_objects.length > 1
                  end
                  tmp_objects.each do |tmp_obj|
                    tmp_text += debug_field_analyse(tmp_obj, tmp_setup_child)
                  end    
                end
              end                
          end
        else
          tmp_text += "\n" + text_indent + "- #{elem.name} : #{elem.macro.to_s}"           
        end
        
      end
    end

    tmp_text
  end
  
  def self.read_debug_field_file(debug_code)
    debug_field_return = {}
    tmp_file_name = File.expand_path(File.join(Dir.getwd,"config") + "/cross_table.yml")
    tmp_message = ""
    unless File.exist?(tmp_file_name)
#      tmp_message = "File '#{tmp_file_name}' does not exist"
      debug_field_return[:setup] = {debug_code.to_sym => nil}
    else
      begin
        tmp_config = YAML.load_file(tmp_file_name)
        if tmp_config[debug_code].nil? then
#          tmp_message = "This element '#{debug_code}' is not available"
          debug_field_return[:setup] = {debug_code.to_sym => nil}
        else
          debug_field_return[:setup] = tmp_config[debug_code] 
        end
      rescue => e
        tmp_message = e.message 
      end    
    end
    debug_field_return[:error_message] = tmp_message
    return debug_field_return
  end    
  
  def self.is_numeric?(to_test)
    true if Float(to_test) rescue false
  end
  
  def self.to_bool(to_test)    
    return true   if to_test == true   || to_test =~ (/(true|t|yes|y|1)$/i)
    return false  if to_test == false  || to_test.blank? || to_test =~ (/(false|f|no|n|0|N.A)$/i)    
    raise ArgumentError.new("invalid value for Boolean: \"#{to_test}\"")  
  end

  def self.help_text
    tmp_text = "Help for 'cross_table' method :"
    tmp_text += "\n    Syntax : obj.cross_table(options = {})"    
    tmp_text += "\n    Exemples for Class object"    
    tmp_text += "\n        to show all tables linked from a Class"    
    tmp_text += "\n            => Class.cross_table"    
    tmp_text += "\n        to show all tables linked from a Class using a filter"    
    tmp_text += "\n            => Class.cross_table(:filter => ['Classname1', 'Classname2', '...'])"    
    tmp_text += "\n        to show a setup YML from a Class. No filter seems all relations"    
    tmp_text += "\n            => Class.cross_table(:filter => ['Classname1', 'Classname2', '...'], :show_setup => true)"    
    tmp_text += "\n        to create a setup YML file from a Class if it does not exist yet. No filter seems all relations"    
    tmp_text += "\n            => Class.cross_table(:filter => ['Classname1', 'Classname2', '...'], :setup_file => true)"    
    tmp_text += "\n    Exemple for Instance object"
    tmp_text += "\n        to show all information about the Instance"    
    tmp_text += "\n            => ClassInstance.cross_table"    
    tmp_text += "\n        to show YML format"    
    tmp_text += "\n            => ClassInstance.cross_table(:format => 'YML')"    
    tmp_text += "\n            use 'YMLID' to add record ids"    
    tmp_text += "\n        to show fixtures"    
    tmp_text += "\n            => ClassInstance.cross_table(:format => 'fixture')"    
    tmp_text += "\n        to show all information about the Instance and Class linked"    
    tmp_text += "\n            => ClassInstance.cross_table(:class => true)"    
    tmp_text += "\n        to show all links from a Instance of a table Class."    
    tmp_text += "\n            :root initialize the beginning of the analyse"    
    tmp_text += "\n            YML file 'cross_table.yml' has to exist into '<application>/config' directory"    
    tmp_text += "\n            => ClassInstance.cross_table(:root => 'code_into_file')"
  end
  
  def self.debug_hash(tmp_hash)
    tmp_text = "\n\n\n\n"
    tmp_text += tmp_hash.inspect
    tmp_hash.each do |tmp_key,tmp_value|
        tmp_text += "\n    - #{tmp_key} : #{tmp_value}"          
    end
    tmp_text += "\n\n\n\n"
  end


end

ActiveRecord::Base.send :include, CrossTable

