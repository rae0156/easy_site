# encoding: UTF-8
module SetupModule
  
    def get_module_setup(path,name,default=nil)
      esmodule = EsModule.find(:first,:conditions => {:path_setup => path,:setup_name => name, :module_name => @module_name})
      return esmodule.present? ? esmodule.value : default       
    end
    
    def get_module_setup_multi(path,options={})
      mode = options[:mode].presence || "hash_value"
      esmodules = EsModule.find(:all,:conditions => ["path_setup like ? and module_name = ? ","#{path}%", @module_name])
      case mode.downcase
      when "collection"
        return esmodules
      when "array_value"
        return esmodules.collect(&:value)
      when "array_hash"
        return esmodules.map{ |m| {:path => m.path_setup, :name => m.setup_name, :value => m.value}}
      when "hash_value"
        tmp={}
        esmodules.each do |m|
          tmp[m.setup_name.to_sym] = m.value  
        end        
        return tmp
      end
    end
  
  
end


module InterfaceModels
  module AddActAsMethods
    
    
    def self.included(base)
       base.extend(AddActAsMethods)
    end
  
  
    def has_es_interface_models
      extend AddActAsMethods::ClassMethods
      extend SetupModule
      include AddActAsMethods::InstanceMethods
    end
  
  
  
    module ClassMethods    
      def init_interface(module_name)
        @module_name=module_name
      end
      
      

    end
    
    module InstanceMethods
    end
  
  
  end

end


ActiveRecord::Base.send(:include, InterfaceModels::AddActAsMethods) 


module InterfaceControllers
  module AddActAsMethods
    
    
    def self.included(base)
       base.extend(AddActAsMethods)
    end
  
  
    def has_es_interface_controllers
      extend AddActAsMethods::ClassMethods
      extend SetupModule
      include AddActAsMethods::InstanceMethods
    end
  
  
  
  
    module ClassMethods    
      def init_interface(module_name)
        @module_name=module_name
        prepend_view_path File.join(Rails.root,'lib','modules',@module_name,'/views')
        # puts "ici : #{self.view_paths.inspect}"
      end
    end
    
    module InstanceMethods
    end
  
  
  end

end

ActionController::Base.send(:include, InterfaceControllers::AddActAsMethods) 
