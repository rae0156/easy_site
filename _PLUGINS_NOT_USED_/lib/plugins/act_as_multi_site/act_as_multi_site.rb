module MultiSite
  module AddActAsMethods  
    
    
    def self.included(base)
       base.extend(AddActAsMethods)
    end
  
  
    def acts_as_multi_site
      #extend AddActAsMethods::ClassMethods
      #include AddActAsMethods::InstanceMethods
      
      EsSite.create({:code => "site",:description =>"premier"}) if EsSite.first.nil?
      default_scope do 
        #first : loaded for sesssion via current_site_id, second : Rails variable, third : first site setup
        if EsSite.current_site_id.blank? || Rails.application.config.default_site.blank?
          site = EsSite.find_by_id(EsSite.current_site_id || Rails.application.config.default_site)  || EsSite.order("id").first
          site_id = site ? site.id : 0
        else  
          site_id = EsSite.current_site_id || Rails.application.config.default_site
        end
        
        where(:es_site_id => site_id) 
      end if self.column_names.include?("es_site_id") #self.new.respond_to?("es_site_id")
    end
  
   
  end

  ActiveRecord::Base.send(:include, AddActAsMethods) 

end
