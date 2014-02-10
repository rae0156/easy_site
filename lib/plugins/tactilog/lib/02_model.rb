module LogModel

  
  def self.included(base)
     
     base.send :extend , ClassMethods
     base.send :include, InstanceMethods
     
  end 


  module ClassMethods    


   def inherited(subclass)
      super
      model_init_log(subclass)
   end

    def log(message=nil, level = ActiveSupport::BufferedLogger::INFO)       
      model_init_log(self) unless self.respond_to?("model_log")
      if message.nil? && self.respond_to?("cross_table")
        tmp_obj = self.find(:first) if ActiveRecord::Base.connection.table_exists?(self.table_name)
        message = ""
        message += "Relation for #{self.name} : " + 10.chr
        message += "================================" + 10.chr
        message += self.cross_table(:format=>"text", :filter => [self.name]) + 10.chr + 10.chr
        message += "Setup for #{self.name} : " + 10.chr
        message += "================================" + 10.chr
        message += self.cross_table(:show_setup => true, :filter => [self.name]) + 10.chr + 10.chr
        unless tmp_obj.blank?
          message += "Sample for #{self.name} : " + 10.chr
          message += "================================" + 10.chr
          message += tmp_obj.log(nil, -1) + 10.chr
        else  
          message += "================================" + 10.chr
          message += "No sample available" + 10.chr
        end
      end
      message||=''
      self.model_log.add(level,message) if level.to_i >= 0
      message      
    end

    def model_init_log(subclass=self)
      subclass.cattr_accessor :model_log
      subclass.model_log = ActiveSupport::BufferedLogger.new(Rails.root.join("log",Rails.env + ".log"))
      subclass.model_log.init_log_setup(subclass.to_s)
      unless subclass.model_log.setup_log.blank?
        subclass.model_log.setup_log['action_model']=subclass.model_log.setup_log['action_model'].to_s
        unless subclass.model_log.setup_log['action_model'].blank?
          if subclass.model_log.setup_log['action_model'].split(",").include?('valivation') || subclass.model_log.setup_log['action_model'].split(",").include?('all')
            subclass.create_instance_method_callback('before_validation')
            subclass.create_instance_method_callback('after_validation')
          end
          if subclass.model_log.setup_log['action_model'].split(",").include?('save') || subclass.model_log.setup_log['action_model'].split(",").include?('all')
            subclass.create_instance_method_callback('before_save')
            subclass.create_instance_method_callback('after_save')
          end
          if subclass.model_log.setup_log['action_model'].split(",").include?('update') || subclass.model_log.setup_log['action_model'].split(",").include?('all')
            subclass.create_instance_method_callback('before_update')
            subclass.create_instance_method_callback('after_update')
          end
          if subclass.model_log.setup_log['action_model'].split(",").include?('create') || subclass.model_log.setup_log['action_model'].split(",").include?('all')
            subclass.create_instance_method_callback('before_create')
            subclass.create_instance_method_callback('after_create')
          end
          if subclass.model_log.setup_log['action_model'].split(",").include?('destroy') || subclass.model_log.setup_log['action_model'].split(",").include?('all')
            subclass.create_instance_method_callback('before_destroy')
            subclass.create_instance_method_callback('after_destroy')
          end
          if subclass.model_log.setup_log['action_model'].split(",").include?('special') || subclass.model_log.setup_log['action_model'].split(",").include?('all')
            subclass.create_instance_method("after_find")
            subclass.create_instance_method("after_initialize")
          end
          #subclass.create_class_method_alias('toto')
          #subclass.list_methods
        end
      end
    end

#    def list_methods
#      log "class method : #{self.methods}"
#      log "instance method: #{self.instance_methods}"
#      self.methods.each do |method|
#        log "   - #{method}"
#      end
#    end

#    def create_class_method_alias(proc_name)
#        metaclass = class << self; self; end
#        metaclass.send(:define_method, proc_name) do
#          log "#{proc_name}"
#        end              
#    end

    def create_instance_method_callback(proc_name)
        self.class_eval do
          define_method "callback_#{proc_name}" do
            log "#{proc_name} : <#{self.class.name}>#{self.id}:#{self.inspect}"
          end
          send proc_name, "callback_#{proc_name}"
        end
    end
    
    def create_instance_method(proc_name)
        self.class_eval do
          define_method proc_name do
            log "#{proc_name} : <#{self.class.name}>#{self.id}:#{self.inspect}"
          end
        end
    end
    
  end
  
  module InstanceMethods
    def log(message=nil, level = ActiveSupport::BufferedLogger::INFO)
      model_init_log(self.class) unless self.respond_to?("model_log")
      if message.nil? && self.respond_to?("cross_table")
        message = ''
        message += "Text format :"
        message += self.cross_table(:format=>"text", :level => (model_log.setup_log['level_model']||'3')) + 10.chr + 10.chr
        message += "YML format :" + 10.chr
        message += self.cross_table(:format=>"YMLID", :level => (model_log.setup_log['level_model']||'3')) + 10.chr + 10.chr
        message += "Fixture format :" + 10.chr
        message += self.cross_table(:format=>"fixture", :level => (model_log.setup_log['level_model']||'3')) + 10.chr
      else
        message||=''
      end
      self.class.log(message,level) if level.to_i >= 0
      message
    end
  end


end

ActiveRecord::Base.send :include, LogModel

