module LogControler

  RAILS_ROOT  = "#{Rails.root}" unless defined?(ROOT_PATH)

  def self.included(base)
      base.send :extend , ClassMethods
      base.send :include, InstanceMethods
  end 

  module ClassMethods    

   def inherited(subclass)
      super
      model_init_log(subclass)
      # necessary for loading application_controler. because, it is not loaded by rails if already loaded before.
      Dir.glob(RAILS_ROOT + '/app/controllers/application_controller.rb').each { |file| require_dependency file }
   end

    def log(message, level = ActiveSupport::BufferedLogger::INFO)     
      self.model_log.add level,message 
    end

    def model_init_log(subclass=self)

      subclass.cattr_accessor :model_log
      subclass.model_log = ActiveSupport::BufferedLogger.new(Rails.root.join("log",Rails.env + ".log"))
      subclass.model_log.init_log_setup(subclass.to_s)
      unless subclass.model_log.setup_log.blank?
        subclass.model_log.setup_log['action_controller']=subclass.model_log.setup_log['action_controller'].to_s
        unless subclass.model_log.setup_log['action_controller'].blank?
          action_list = subclass.model_log.setup_log['action_list'] || ''
          only = action_list.blank? ? {} : {:only => action_list.split(',').map {|elem| elem.to_sym}}
          if subclass.model_log.setup_log['action_controller'].split(",").include?('before') || subclass.model_log.setup_log['action_controller'].split(",").include?('all')
            subclass.before_filter(only){ |c| c.before_filter_log c.action_name }
          end
          if subclass.model_log.setup_log['action_controller'].split(",").include?('after') || subclass.model_log.setup_log['action_controller'].split(",").include?('all')
            subclass.after_filter(only){ |c| c.after_filter_log c.action_name }
          end
        end
      end
    end

  end
  
  module InstanceMethods

    def before_filter_log(action=self.action_name)
      log "before <#{self.class.name}>#{action}"      
    end

    def after_filter_log(action=self.action_name)
      log "after <#{self.class.name}>#{action}"      
    end
      

    def log(message, level = ActiveSupport::BufferedLogger::INFO)
      self.class.log(message,level)
    end
    
  end


end


class ApplicationController < ActionController::Base
  include LogControler

   before_filter :find_client_ip

   private
   def find_client_ip
     model_log.init_client(request.remote_ip) if self.respond_to?("model_log")
   end

end

