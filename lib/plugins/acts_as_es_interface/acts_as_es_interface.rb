# encoding: UTF-8
module SetupModule
  
    def get_module_name
      return @module_name
    end

    def is_module_actif?
      setup = EsModule.find(:first,:conditions => {:path_setup => "",:setup_name => "activated", :module_name => @module_name})
      return !setup.blank? && setup.value=="Y" 
    end
  
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
  
  
    def has_es_interface_models(module_name="")
      @module_name=module_name unless module_name.blank? #manage module_name without lib/modules/
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
  
  
    def has_es_interface_controllers(module_name="")
      @module_name=module_name unless module_name.blank? #manage module_name without lib/modules/
      extend AddActAsMethods::ClassMethods
      extend SetupModule
      include AddActAsMethods::InstanceMethods
      
      before_filter :check_actif_module
      
    end
  
  
  
  
    module ClassMethods    
      def init_interface(module_name)
        @module_name=module_name
        prepend_view_path File.join(Rails.root,'lib','modules',@module_name,'/views')
        # puts "ici : #{self.view_paths.inspect}"
      end
      
    end
    
    module InstanceMethods

      def check_actif_module
        unless self.class.is_module_actif?
          redirect_to :controller => "sites", :action => "error", :error => "Le module '%{module}' est désactivé".trn(:module => self.class.get_module_name)
        end 
      end

      def module_action_part
        module_action_part_var = session.delete(:module_action_part)
        current_user = module_action_part_var[:current_user].presence 
        return generate_part(module_action_part_var[:part_name],module_action_part_var[:content_id])        
      end

private

      def generate_part(part_name,content_detail_id)
        return "" unless self.class.is_module_actif?
        result = ""
        if self.class.private_instance_methods(false).include?(part_name.to_sym)
          part_params={}
          cd = EsContentDetail.find_by_id(content_detail_id)
          cd.es_content_detail_params.each do |param|
            part_params[param.setup_name]=param.value
          end unless cd.blank?

          begin
            result = self.send(part_name,part_params)
          rescue ArgumentError => ex
            result = "Method '#{part_name}' in '#{self.class.name}' : #{ex.message}" 
          end    
        else
          result = "This private method '#{part_name}' does not exist"
        end
        return result
      end

    end
  
  
  end

end

ActionController::Base.send(:include, InterfaceControllers::AddActAsMethods) 


module InterfaceMailers
  module AddActAsMethods
    
    
    def self.included(base)
       base.extend(AddActAsMethods)
    end
  
  
    def has_es_interface_mailers(module_name="")
      @module_name=module_name unless module_name.blank? #manage module_name without lib/modules/
      extend AddActAsMethods::ClassMethods
      include AddActAsMethods::InstanceMethods
    end
  
  
  
  
    module ClassMethods    
      def init_interface(module_name)
        @module_name=module_name
        prepend_view_path File.join(Rails.root,'lib','modules',@module_name,'/views')
      end
      
    end
    
    module InstanceMethods
    end
  
  end

end

ActionMailer::Base.send(:include, InterfaceMailers::AddActAsMethods) 
