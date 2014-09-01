# encoding: UTF-8 

class ModuleLoader

  STRUCTURE_DIR = ['models','controllers','views']
  LOAD_DIR      = ['models','controllers']

  def self.load_all_module
    module_dir = "#{Rails.root}/lib/modules"
    if File.directory?(module_dir) 
      Dir.glob("#{module_dir}/*").each do |file|
        if  File.directory?(file)
          @module = file.split("/").last
          load_one_module(file)
        end           
      end
    end
  end  
  
  private
  
  def self.load_one_module(module_path)  
    if check_module(module_path)  
      load_module_detail(module_path)
      loaded = load_interface
      self.load_setup if loaded && self.test_version
    end     
  end
  
  def self.check_module(module_path)
    return false unless check_module_structure(module_path) 
    return false unless check_module_interface(module_path) 
    return false unless check_table_structure 
    true    
  end  
  
  def self.check_table_structure
    if @interface["installation"].present? && @interface["installation"]["table_verification"].present? 
      error_structure=true
      @interface["installation"]["table_verification"].each do |table|
        if table.is_a?(String)
          unless ActiveRecord::Base.connection.table_exists? table
            puts "Le module '#{@module}' ne peut pas être installé. La table '#{table}' n'existe pas."
            error_structure=false
          end
        elsif table.is_a?(Hash)  
          table.each do |k,field|
            table_name = k
            if !ActiveRecord::Base.connection.table_exists? table_name
              puts "Le module '#{@module}' ne peut pas être installé. La table '#{table_name}' n'existe pas."
              error_structure=false
            elsif field.is_a?(Array)
              fields = []
              field.each do |f|
                if f.is_a?(String)
                  fields << f
                end
              end
              fields.sort!
              table_fields = ActiveRecord::Base.connection.columns(table_name).collect(&:name).sort
              unless fields.uniq == table_fields.uniq
                puts "Le module '#{@module}' ne peut pas être installé. La structure de la table '#{table_name}' n'est pas correcte. Les champs de la table devraient être '#{fields.join(',')}' et sont en réalité '#{table_fields.join(',')}'."
                error_structure=false                
              end
            end
          end
        end
        
      end
      return error_structure
    else
      return true
    end
  end
  
  def self.check_module_interface(module_path)
    yml_file = File.join(module_path,@module + ".yml")
    unless File.exist?(yml_file)
      puts "Le module '#{@module}' n'a pas d'interface"
      return false 
    end
    @interface = YAML.load(File.read(yml_file))  
    unless (@interface["interface"].present? && @interface["interface"]["models"].present? && @interface["interface"]["controllers"].present?)
      puts "La structure du fichier yml du module '#{@module}' n'est pas correcte"
      return false 
    end
    return true
  end
  
  def self.check_module_structure(module_path)
    STRUCTURE_DIR.each do |sub_rep|
      unless File.directory?(File.join(module_path,sub_rep))
        puts "Le module '#{@module}' n'a pas une structure de répertoire correcte"
        return false 
      end
    end
    return true
  end
  
  def self.load_module_detail(module_path)
    LOAD_DIR.each do |sub_rep|
      Dir.glob("#{File.join(module_path,sub_rep)}/*").each do |file|
        require file
      end
    end
    
  end

  def self.test_version
    version = (@interface["version"] || "0.0.0.0").split('.')
    if version.size==4 && version[0].is_integer?(3) && version[1].is_integer?(3) && version[2].is_integer?(3) && version[3].is_integer?(3)
      (0..3).each {|i| version[i]=version[i].rjust(3, '0')}
      esmodule = EsModule.find(:first , :conditions=> {:module_name => @module, :setup_name => "version", :path_setup => ""})
      current_version=''
      if !esmodule.blank? 
        tmp_current_version = esmodule.value.split('.')
        if tmp_current_version.size==4 && tmp_current_version[0].is_integer?(3) && tmp_current_version[1].is_integer?(3) && tmp_current_version[2].is_integer?(3) && tmp_current_version[3].is_integer?(3)
          (0..3).each {|i| tmp_current_version[i]=tmp_current_version[i].rjust(3, '0')}
          current_version = tmp_current_version
        end
      end
      if esmodule.blank? || current_version.blank? || version.join('') > current_version.join('')
        return true
      else
        puts "La version du module '#{@module}' (#{version.join('.')}) installé est la même ou est plus récente que celle du fichier YML (#{current_version.join('.')})"  
        return false
      end
    end
  end
  
  def self.load_setup
    puts "Chargement du setup pour le module '#{@module}'"  
    load_setup_part(@interface.except("interface","installation"))
  end
  
  def self.load_setup_part(element,path='')
    element.each do |k,v|
      if v.is_a?(Hash)
        load_setup_part(element[k],path + k.to_s + '/')
      elsif v.is_a?(Array)
        create_a_module_setup(path, k.to_s, v.join(','))        
      else    
        create_a_module_setup(path, k.to_s, v)      
      end
    end
  end

  def self.create_a_module_setup(path,setup_name,value)
    path = path[0..-2] if path[-1]=='/'
    esmodule=EsModule.find(:first,:conditions => {:module_name => @module, :path_setup => path, :setup_name => setup_name})
    
    param_setup= nil
    type_setup = nil
    updatable = 'N'
    value = value.strip
    if value.ends_with?(">>")
      tmp_find = value.rindex('<<')
      if !tmp_find.blank? && tmp_find>0
        param_setup = value[tmp_find+2..-3].split('-')
        value = value[0..tmp_find-1].rstrip
      else
        param_setup = value.strip[2..-3].split('-')
        value = ""
      end  
    end
    
    unless param_setup.blank?
      type_setup  = param_setup[0]
      updatable   = param_setup[1] || 'Y'
      description = param_setup[2] || ''
      value_list  = param_setup[3] || ''
    end

    description = setup_name if description.blank?

    if esmodule
      esmodule.update_attributes({:type_setup => type_setup,:value => value,:updatable => updatable,:description => description, :value_list => value_list})
    else
      EsModule.create(:module_name => @module, :path_setup => path, :setup_name => setup_name, :value => value, :type_setup => type_setup,:updatable => updatable,:description => description, :value_list => value_list)
    end
  end

  def self.load_interface
    error = false
    LOAD_DIR.each do |element|
      if @interface["interface"][element].is_a?(Array)
        @interface["interface"][element].each do |class_name|
          if class_exists?(class_name)
            classe = class_name.constantize
            if classe.respond_to?("init_interface")              
              classe.init_interface(@module)
              puts "interface installé et initialisé pour la class '#{element}' - '#{class_name}'."
            else
              error = true
              puts "Erreur dans le module '#{@module}' : l'interface '#{element}' n'a pas été implémenté dans la class '#{class_name}'. 'has_es_interface_#{element}' n'existe pas dans cette class"  
            end
          else
            error = true
            puts "Erreur dans le module '#{@module}' : la class '#{class_name}' n'existe pas"  
          end
        end
      elsif @interface["interface"][element] == "/"
        puts "module '#{@module}' : Pas de liste d'éléments interfacés pour '#{element}'"  
      else
        error = true
        puts "Erreur dans le module '#{@module}' : Pas de liste d'éléments interfacés pour '#{element}'"  
      end      
    end
    return !error
  end
  
  
  
  def self.class_exists?(class_name)
    return Object.const_defined?(class_name)
  rescue 
    return false
  end
  
end

ModuleLoader.load_all_module