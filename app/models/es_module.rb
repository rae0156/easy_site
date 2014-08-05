# encoding: UTF-8

class EsModule < ActiveRecord::Base
  acts_as_dynamic_model 
  
  def self.get_module(module_name)
    return  EsModule.new({:module_name => module_name})
  end

  def self.version(module_name)
    m = EsModule.first(:conditions=> {:module_name => module_name, :path_setup => '', :setup_name => "version"})
    return m.blank? ? '0.0.0.0' : m.value
  end
  

  def get_module_setup
    tabs=[]
    tabs << get_main_setup
    tabs << get_main_admin
    tabs << get_entry_points
    return tabs
  end  
  
  def self.save_setup(module_name,options_to_save={})
    @module_name = module_name
    return unless module_name==options_to_save[:module_name].presence
    save_main_setup(options_to_save)
    save_main_admin(options_to_save)
  end
  
private 
 
  def get_main_setup
    tab = {}
    tab[:title]   = "Paramétrage principal".trn
    tab[:title_1] = "Général".trn
    tmp_setup = []
    tmp_setup << add_setup("module_name", self.module_name                                 , :description=>"Nom du module"           , :read_only => "Y")
    tmp_setup << add_setup("version"    , self.class.version(self.module_name)             , :description=>"Version du module"       , :read_only => "Y")
    tab[:group_1] = tmp_setup

    tmp_setup = []
    tmp_setup << add_setup("activate"   , find_or_create_setup("activated","Y","boolean")  , :description=>"Module actif"  , :format => "boolean")
    tab[:group_2] = tmp_setup

    return tab
  end

  def get_main_admin
    tab = {}
    tab[:title]   = "Administration".trn
    tab[:title_1] = "Paramétrages globaux".trn
    tmp_setup = []
    tmp_setup << add_setup("title"   , find_or_create_setup("setup/admin/title",self.module_name)  , :description=>"Titre du module")
    tab[:group_1] = tmp_setup

    tab[:title_2] = "Paramétrages spécifiques au module #{self.module_name}".trn
    tmp_setup = []
    setups = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","setup/admin/specific",self.module_name])
    setups.each_with_index do |setup,i| 
      tmp_setup << add_setup("admin_#{setup.setup_name}"   , setup.value  , :description => setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'), :value_list => setup.value_list.split(','))
    end
    tab[:group_2] = tmp_setup
    return tab
  end

  def get_entry_points
    tab = {}
    tab[:title]   = "Points d'entrée".trn
    setup_controllers = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","controllers/entry_point_names",self.module_name])
    setup_controllers.each_with_index do |sc,i|
      tmp_setup = []
      setups = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","controllers/entry_points/#{sc.setup_name}",self.module_name])
      setups.each_with_index do |setup,j| 
        tmp_setup << add_setup("entry_points_#{j}"    , setup.setup_name             , :description=>setup.value       , :read_only => "Y")
      end
      tab["title_#{i+1}".to_sym]   = "Contrôleur #{sc.value}".trn + " (#{sc.setup_name})"
      tab["group_#{i+1}".to_sym] = tmp_setup
    end

    return tab
  end

   
  def add_setup(name, value = "",options = {})
    options[:description] ||= ""
    options[:format]      ||= "string"
    options[:mandatory]   ||= "N"
    options[:read_only]   ||= "N"
    value=value.split(",") if options[:format] == "multiple_list"
    return {:name => name ,:description=>options[:description].trn  ,:format => options[:format], :value => value,:read_only => options[:read_only], :mandatory => options[:mandatory], :value_list => options[:value_list] }
  end  
  
  
  def find_or_create_setup(full_path_name,default="",format = "string")
    path,name=self.class.split_full_path_name(full_path_name)
    tmp_module_setup = EsModule.find(:first,:conditions => ["path_setup = ? AND setup_name = ? AND module_name = ?",path,name,self.module_name])
    unless tmp_module_setup
      tmp_module_setup = EsModule.create({:path_setup => path, :setup_name => name, :value => default, :type_setup => format, :module_name => self.module_name, :updatable => "Y"})
    end
    return tmp_module_setup.value
  end
  
  def self.save_main_setup(options_to_save={})
    save_one_setup(options_to_save["activate"],"activated") if options_to_save["activate"].present?
  end
  
  def self.save_main_admin(options_to_save={})
    save_one_setup(options_to_save["title"],"setup/admin/title") if options_to_save["title"].present?

    options_to_save.select{|k,v| k.to_s.start_with?("admin_")}.each do |k,v|
      save_one_setup(v,"setup/admin/specific/#{k.to_s[6..-1]}") 
    end    
  end
  
  def self.save_one_setup(value,full_path_name="")
    path,name=split_full_path_name(full_path_name)
    setup = EsModule.find(:first,:conditions=> {:path_setup => path, :setup_name => name, :module_name => @module_name})
    if setup && setup.updatable=='Y'      
      if setup.type_setup == 'multiple_list'
        tmp_value = []
        value.each do |v|
          tmp_value << v if setup.value_list.split(',').include?(v)  
        end
        tmp_value = tmp_value.join(',')
      else
        tmp_value = value
      end
      setup.update_attribute("value",tmp_value)
    end
  end
  
  def self.split_full_path_name(full_path_name="")
    full_path_name_array = full_path_name.split('/')
    name = full_path_name_array.last
    path = full_path_name_array.size > 1 ? full_path_name_array[0..-2].join('/')  : ""
    return path,name
  end
  
end