module MultiSite
  module AddActAsMethods  
    
    
    def self.included(base)
       base.extend(AddActAsMethods)
    end
  
  
    def acts_as_multi_site
      extend AddActAsMethods::ClassMethods
      include AddActAsMethods::InstanceMethods
      
      EsSite.create({:code => "site",:description =>"premier"}) if EsSite.first.nil?
      default_scope do 
        #first : loaded for sesssion via current_site_id, second : Rails variable, third : first site setup
        site = EsSite.find_by_id(EsSite.current_site_id || Rails.application.config.default_site)  || EsSite.order("id").first
        site_id = site ? site.id : 0
        where(:es_site_id => site_id) 
      end if self.new.respond_to?("es_site_id")
    end
  
  
  
    module ClassMethods    
        def class_proc()
          AddActAsMethods.private_proc()
        end
    end
    
    module InstanceMethods
      def instance_proc()
        AddActAsMethods.private_proc()
      end 
    end
  
  
    private 
    
    
    def self.private_proc()
    end
  
 
  end

  ActiveRecord::Base.send(:include, AddActAsMethods) 

end
