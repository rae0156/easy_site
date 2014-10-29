# encoding: UTF-8 
module ActionDetectController 
  module AddActAsMethods 
    
    
    def self.included(base) 
       base.extend(AddActAsMethods) 
    end 
  
  
    def has_actions_detect(name_param_list=[],action_only_list=nil) 
      include AddActAsMethods::InstanceMethods 
      before_filter :only => action_only_list do |c|
        c.detect_params(name_param_list)
      end 
    end 
  
  
  
  
    module InstanceMethods 
      def detect_params(name_param_list) 
        ActionUser.init_param_from_controller #init params_from_controller 
        name_param_list.each do |p| 
          if params[p].present? 
            ActionUser.init_param_from_controller(p, params[p]) 
          end 
        end if name_param_list.is_a?(Array) 
      end 
    end 
  
  
  end 

end 

ActionController::Base.send(:include, ActionDetectController::AddActAsMethods) 

