# encoding: UTF-8

class EsModule < ActiveRecord::Base
  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Module".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.module_name + " " + self.setup_name
  end
  
  def self.get_module_params(controller_name,action_name)
    module_params=[]
    EsModule.all(:conditions => ["path_setup like ?","controllers/contents/#{controller_name}/#{action_name}/params"]).each do |s|
      module_params << s
    end
    return module_params
  end

  def self.is_params?(module_action_name)
    module_action_name_param = module_action_name.gsub(' ','/')
    return !EsModule.first(:conditions => ["path_setup like ?","controllers/contents/#{module_action_name_param}/params"]).blank?
  end
  
  
  def self.get_module_params_from_content_detail(content_detail_id)
    tab = {}
    content_detail = EsContentDetail.find(content_detail_id)
    if !content_detail.blank? && !content_detail.module_action_name.blank?
      module_action_name = content_detail.module_action_name.split(" ") 
      module_name = EsModule.find_by_path_setup("controllers/contents/#{module_action_name[0]}/#{module_action_name[1]}").module_name      
      tmp_module = EsModule.find(:first,:conditions => ["path_setup = ? AND setup_name = ? AND module_name = ?","controllers/contents/#{module_action_name[0]}/#{module_action_name[1]}", 'description', module_name])
      if tmp_module
        tab[:title_1] = "Paramétrages de la partie '%{part}' du module '%{module}'".trn(:module => tmp_module.module_name, :part => tmp_module.value)
      else
        tab[:title_1] = "Paramétrages du module %{module}".trn(:module => module_name)
      end
      tmp_setup = []
      content_detail.es_content_detail_params.each_with_index do |setup,i| 
        tmp_setup << add_setup(setup.setup_name, setup.value  , :description => setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'), :value_list => (setup.value_list || "").split(','), :addon_params => setup.value_list)
      end
      tab[:group_1] = tmp_setup
    end
    return [tab]
  end
    
  
  def self.get_module_action_list_choice(module_name='')
    action_list=[]
    EsModule.all(:conditions => ["path_setup like ? AND setup_name='description'","controllers/contents/%"]).each do |s|
      path_setup = s.path_setup.split('/')
      next unless path_setup.size == 4
      if module_name=='' || s.module_name==module_name
        action = ["#{s.module_name} : #{s.value}","#{path_setup[2]} #{path_setup[3]}"]
        action_list << action unless action_list.include?(action)
      end
    end
    
    return action_list    
  end
  
  def self.get_module_action_list(module_name='')
    action_list=[]
    EsModule.all(:conditions => ["path_setup like ?","controllers/contents/%"]).each do |s|
      path_setup = s.path_setup.split('/')
      next unless path_setup.size == 4
      if module_name=='' || s.module_name==module_name
        action = "#{path_setup[2]} #{path_setup[3]}"
        action_list << action unless action_list.include?(action)
      end
    end
    
    return action_list    
  end
  
  def self.get_module(module_name)
    return  EsModule.new({:module_name => module_name})
  end

  def self.version(module_name)
    m = EsModule.first(:conditions=> {:module_name => module_name, :path_setup => '', :setup_name => "version"})
    return m.blank? ? '0.0.0.0' : m.value
  end

  def self.is_installed?(module_name)
    return !EsModule.first(:conditions=> {:module_name => module_name, :path_setup => '', :setup_name => "version"}).blank?
  end

  
  def self.activated(module_name)
    m = EsModule.first(:conditions=> {:module_name => module_name, :path_setup => '', :setup_name => "activated"})
    return (m.blank? ? 'N': m.value)=="Y"
  end
  

  def get_module_setup
    tabs=[]
    tabs << get_main_setup
    tabs << get_main_admin
    tabs << get_entry_points
    tabs << get_contents
    tabs << get_menus
    return tabs
  end  
  
  def self.save_setup(module_name,options_to_save={})
    @module_name = module_name
    return unless module_name==options_to_save[:module_name].presence
    save_main_setup(options_to_save)
    save_main_admin(options_to_save)
    save_content_setup(options_to_save)
    save_menu(options_to_save)
  end
  
  def self.get_menu_by_module
    result = {}
    modules = EsModule.find :all, :order => "module_name", :group => "es_modules.module_name"
    modules.each do |m|
      EsModule.get_menu_list(m.module_name).each do |menu|
        result[m.module_name] = [] unless result[m.module_name].present?
        result[m.module_name] << [menu[0],menu[2]]
      end
    end    
    result
  end

  def self.get_url_from_module_menu(code)
    modules = EsModule.find :all, :order => "module_name", :group => "es_modules.module_name"
    modules.each do |m|
      EsModule.get_menu_list(m.module_name).each do |menu|
        return menu[1] if menu[2]==code
      end
    end    
    return "#"
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
    setup = find_or_create_setup("activated","N","boolean","Module actif","Y")
    tmp_setup << add_setup("activate"   ,  setup.value , :description=>setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'))
    tab[:group_2] = tmp_setup

    return tab
  end

  def get_menus
    setup1 = EsModule.find(:first,:conditions => ["path_setup = ? AND module_name = ? AND setup_name = ?","menus",self.module_name,"models"])
    tab = {}
    tab[:title]   = "Paramétrage menu".trn
    tab[:title_1] = "Options à inclure".trn
    tmp_setup = []
    setup = find_or_create_setup("menus/menu_entry_points","Y","boolean","Inclure les points d'entrée","Y")
    tmp_setup << add_setup("menu_entry_points", setup.value, :description=>setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'))
    if setup1 && !setup1.value.blank?
      setup = find_or_create_setup("menus/menu_models","Y","boolean","Inclure les modèles","Y")
      tmp_setup << add_setup("menu_models", setup.value , :description=>setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'))
    end
    tab[:group_1] = tmp_setup

    tab[:title_2] = "Liste des modèles à interroger".trn
    tmp_setup = []
    if setup1 
      setup1.value.split(',').each_with_index do |m,i|
        tmp_setup << add_setup("menu_model_#{m.downcase}", m , :format => 'text')
      end
    end
    tab[:group_2] = tmp_setup

    tab[:title_3] = "Liste de menus disponnibles".trn
    tmp_setup = []
    EsModule.get_menu_list(self.module_name).each_with_index do |m,j|
      tmp_setup << add_setup("menus_links_#{j}_link" , m[0]  , :description => m[2], :format => "link",:addon_params => m[1])      
    end
    tab[:group_3] = tmp_setup

    return tab
  end


  def get_main_admin
    tab = {}
    tab[:title]   = "Administration".trn
    tab[:title_1] = "Paramétrages globaux".trn
    tmp_setup = []
    setup = find_or_create_setup("setup/admin/title",self.module_name,"string","Titre du module", "Y")
    tmp_setup << add_setup("title"   , setup.value  , :description=>setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'))
    tab[:group_1] = tmp_setup

    tab[:title_2] = "Paramétrages spécifiques au module %{module}".trn(:module => self.module_name)
    tmp_setup = []
    setups = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","setup/admin/specific",self.module_name])
    setups.each_with_index do |s,i| 
      tmp_setup << add_setup("admin_#{s.setup_name}"   , s.value  , :description => s.description, :format => s.type_setup, :read_only => (s.updatable=='N' ? 'Y' : 'N'), :value_list => (s.value_list || "").split(','))
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
        tmp_setup << add_setup("entry_points_#{j}"      , setup.setup_name             , :description=>setup.value       , :read_only => "Y")
        tmp_setup << add_setup("entry_points_#{j}_link" , "Aller vers".trn + "... #{setup.value}"  , :description => "", :format => "link",:addon_params => {:controller => sc.setup_name[0..-11].underscore, :action => setup.setup_name})
      end
      tab["title_#{i+1}".to_sym]   = "Contrôleur %{controller}".trn(:controller => sc.value) + " (#{sc.setup_name})"
      tab["group_#{i+1}".to_sym] = tmp_setup
    end

    return tab
  end

  def get_contents
    tab = {}
    tab[:title]   = "Contenus".trn
    
    self.class.get_module_action_list(self.module_name).each_with_index do |action,i|
      tmp_setup = []
      setup_description = EsModule.find(:first,:conditions => ["path_setup = ? AND setup_name = ? AND module_name = ?","controllers/contents/#{action.gsub(' ','/')}",'description',self.module_name])
      setups = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","controllers/contents/#{action.gsub(' ','/')}/params",self.module_name])
      if setups.size==0
        tmp_setup << add_setup("nocontent_#{i}"      , 'Pas de paramétrage pour ce contenu'.trn             ,:format => 'text', :description=>''       , :read_only => "Y")
      else
        setups.each_with_index do |setup,j| 
          tmp_setup << add_setup("content_#{setup.id}"   , setup.value  , :description => setup.description, :format => setup.type_setup, :read_only => (setup.updatable=='N' ? 'Y' : 'N'), :value_list => (setup.value_list || "").split(','), :addon_params => setup.value_list)
        end
      end
      tab["title_#{i+1}".to_sym]   = "Contenu '%{action}'".trn(:action => (setup_description.blank? ? action : setup_description.value))
      tab["group_#{i+1}".to_sym] = tmp_setup
    end

    return tab
  end
 

  def add_setup(name, value = "",options = {})
    return self.class.add_setup(name, value, options)
  end  
   
  def self.add_setup(name, value = "",options = {})
    options[:description] ||= ""
    options[:format]      ||= "string"
    options[:mandatory]   ||= "N"
    options[:read_only]   ||= "N"
    options[:addon_params]||= nil
    value=value.split(",") if options[:format] == "multiple_list"
    return {:name => name ,:description=>options[:description].trn  ,:format => options[:format], :value => value,:read_only => options[:read_only], :mandatory => options[:mandatory], :value_list => options[:value_list],:addon_params => options[:addon_params] }
  end  
  
  
  def find_or_create_setup(full_path_name,default="",format = "string",description = "",updatable = "Y")
    path,name=self.class.split_full_path_name(full_path_name)
    tmp_module_setup = EsModule.find(:first,:conditions => ["path_setup = ? AND setup_name = ? AND module_name = ?",path,name,self.module_name])
    unless tmp_module_setup
      tmp_module_setup = EsModule.create({:path_setup => path, :setup_name => name, :value => default, :type_setup => format, :module_name => self.module_name, :updatable => updatable, :description => description})
    end
    return tmp_module_setup
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
  
  def self.save_menu(options_to_save={})
    save_one_setup(options_to_save["menu_entry_points"],"menus/menu_entry_points") if options_to_save["menu_entry_points"].present?
    save_one_setup(options_to_save["menu_models"],"menus/menu_models") if options_to_save["menu_models"].present?
  end
  
  def self.save_content_setup(options_to_save={})
    options_to_save.select{|k,v| k.to_s.start_with?("content_")}.each do |k,v|
      save_one_setup(v,k.to_s[8..-1].to_i) 
    end    
  end

  
  def self.save_one_setup(value,ident="")
    if ident.is_a?(Integer)
      setup = EsModule.find_by_id(ident)
    else
      path,name=split_full_path_name(ident)
      setup = EsModule.find(:first,:conditions=> {:path_setup => path, :setup_name => name, :module_name => @module_name})
    end
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
  
  def self.get_menu_list(module_name)
    menus=[]
    setup1 = EsModule.find(:first,:conditions => ["path_setup = ? AND module_name = ? AND setup_name = ?","menus",module_name,"menu_entry_points"])
    if setup1 && setup1.value=='Y'
      setup_controllers = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","controllers/entry_point_names",module_name])
      setup_controllers.each_with_index do |sc,i|
        tmp_setup = []
        setups = EsModule.find(:all,:conditions => ["path_setup = ? AND module_name = ?","controllers/entry_points/#{sc.setup_name}",module_name])
        setups.each_with_index do |s,j| 
          menus << [s.value,{:controller => sc.setup_name[0..-11].underscore, :action => s.setup_name},"EP_" + sc.setup_name[0..-11].underscore + '_' + s.setup_name]
        end
      end
    end
    
    setup1 = EsModule.find(:first,:conditions => ["path_setup = ? AND module_name = ? AND setup_name = ?","menus",module_name,"menu_models"])
    if setup1 && setup1.value=='Y'
      setup = EsModule.find(:first,:conditions => ["path_setup = ? AND module_name = ? AND setup_name = ?","menus",module_name,"models"])
      if setup 
        setup.value.split(',').each_with_index do |m,i|
          
          if class_exists?(m)
            model = m.constantize
            if model.respond_to?("get_menu_list")              
              result = model.get_menu_list
              if result.is_a?(Array)
                result.each do |r|
                  if r.is_a?(Array) && r.size==3
                    menus << [r[0],r[1],m + "_"+ r[2].underscore]
                  end
                end
              end
            end
          end
          
        end
      end
    end    
    return menus
  end
  
end