class LogYamlSetup
  require 'fileutils'  
  require 'yaml'

  RAILS_ROOT  = "#{Rails.root}" unless defined?(ROOT_PATH)
  
  SETUP_FILE_NAME = File.join(RAILS_ROOT,'config','tactilog.yml')
  
  attr_accessor :setup
  
  def self.create_or_replace_setup
    rails_env = (ENV['RAILS_VERSION'].blank? ? Rails::VERSION::STRING : ENV['RAILS_VERSION'])[0]

    setup_log = init_setup  
    if File.exist?(SETUP_FILE_NAME)     
      
      file_yml = File.open(SETUP_FILE_NAME)
      tmp_hash = {}
      if rails_env == '3'
        YAML::load_documents( file_yml ) do |doc|
          tmp_hash.merge!(doc) if doc.is_a?(Hash)
        end
      else
        YAML::load_stream(file_yml).documents.each do |doc|
          tmp_hash.merge!(doc) if doc.is_a?(Hash)
        end
      end

      setup_log['default'].merge!(tmp_hash['default'] ) 
      setup_log.merge!(tmp_hash.except("default","sample_model","sample_env","sample_controller") ) 
      FileUtils.rm_f(SETUP_FILE_NAME)
    end

    File.open(SETUP_FILE_NAME, 'w') do |out|   # To file
       out.puts "#Please stop and start server after changing this file"
       out.puts ""
       out.puts "#Default setup"
       YAML.dump(setup_log.slice("default"), out)
       out.puts "#Specific setup"
       YAML.dump(setup_log.except("default","sample_model","sample_env","sample_controller"), out)
       out.puts ""
       out.puts "#sample model"
       YAML.dump(setup_log.slice("sample_model"), out)
       out.puts "#sample controller"
       YAML.dump(setup_log.slice("sample_controller"), out)
       out.puts "#sample environment"
       YAML.dump(setup_log.slice("sample_env"), out)
    end
    
    setup_log
  end

  def self.get_setup(env_name,class_name)
    
    
    tmp_setup_log = LogYamlSetup.create_or_replace_setup()
    setup_log = tmp_setup_log["default"]
    is_controller = class_name[-10..-1]=="controller"

    if test_scope((setup_log["scope"] || ''),env_name,is_controller,class_name)
      class_name = "#{class_name[0..-11]}_controller" if is_controller

      setup_log = setup_log.merge(tmp_setup_log["#{env_name}_env"]) if tmp_setup_log.has_key?("#{env_name}_env")
      unless is_controller
        setup_log = setup_log.merge(tmp_setup_log["#{class_name}_model"]) if !class_name.blank? && tmp_setup_log.has_key?("#{class_name}_model")
      else  
        setup_log = setup_log.merge(tmp_setup_log["#{class_name}"]) if !class_name.blank? && tmp_setup_log.has_key?("#{class_name}")
      end
    else
        setup_log = {}
    end

    setup_log
    
  end


private
    
  def self.test_scope(scope,env_name,is_controller,class_name)
    return false if scope=="nothing"
    scope=scope.downcase.split(",")
    env_name = env_name.downcase
    class_name = class_name.downcase
    scope_env = scope.include?("env:#{env_name}") || scope.include?("env:[all]")   
    if class_name.blank?
      return scope_env
    elsif is_controller
      return scope_env && (scope.include?("controller:#{class_name}") || scope.include?("controller:[all]")) 
    else  
      return scope_env && (scope.include?("model:#{class_name}") || scope.include?("model:[all]")) 
    end
  end
    
  def self.init_setup
    { 
      'default' => 
          { 'format' => "%prefix% [%level%: %user% %month%%day% %time% %milli% %pid%-%client%] %logid% (%timing%)",
            'prefix' => 'Tacti@log', 
            'file' => '%env%_tactical.log',
            'action_model' => 'valivation,save,update,create,destroy,special',
            'action_controller' => 'before,after',
            'action_list' => 'index',
            'user_field' => 'login',
            'user_justify' => 10,
            'level' => 'DEBUG',
            'console' => false,
            'level_model' => 3,
            'log_to' => 'file',
            'scope' => "ENV:development,MODEL:[ALL],CONTROLLER:[ALL]"
          },
          
        
          
          
          
      'sample_env' => 
          {'file' => '%env%_tactical.log',
           'console' => true,
           'log_to' => 'table'
          },
          
      'sample_model' => 
          {'file' => '%env%_tactical_%class%.log',
           'level' => 'DEBUG', 
           'action_model' => 'all'
          },

      'sample_controller' => 
          {'file' => '%env%_tactical_%class%.log',
           'action_controller' => 'all',
          }
    }     
  end
  
  def self.help_text
    tmp_text = "Help for 'Tactilog' method :"
    tmp_text += "\n    Instead of 'puts', you may use 'log' instruction and it works."    
    tmp_text += "\n        - you may use 'log' within a model, a controller or everywhere"    
    tmp_text += "\n        - 'log' in a model and without parameters run the 'CrossTable' module"    
    tmp_text += "\n    It is possible to set up the module by environment, by model or by controller"
    tmp_text += "\n        - default setup is added under 'default' code"
    tmp_text += "\n        - for an environment, the code is 'xxxx_env' with xxx = environment name"
    tmp_text += "\n        - for a model, the code is 'xxxx_model' with xxx = model name"
    tmp_text += "\n        - for a controller, the code is 'xxxx_controller' with xxx = controller name"
    tmp_text += "\n    The setting list : "
    tmp_text += "\n       - format            : message format"
    tmp_text += "\n           ex : '%prefix% [%level%: %user% %month%%day% %time% %milli% %pid%] %logid% (%timing%)'"
    tmp_text += "\n       - prefix            : prefix for each line"
    tmp_text += "\n           ex : 'Tacti@log'"
    tmp_text += "\n       - file              : file name"
    tmp_text += "\n           ex : '%env%_tactical.log'"
    tmp_text += "\n       - action_model      : list of type of action for model to log (all for all actions)"
    tmp_text += "\n           ex : 'valivation,save,update,create,destroy,special'"
    tmp_text += "\n       - action_controller : type of action to log (before and/or after or all)"
    tmp_text += "\n           ex : 'before,after'"
    tmp_text += "\n       - action_list       : list of controller action to log (nothing for all actions)"
    tmp_text += "\n           ex : 'index'"
    tmp_text += "\n       - user_field        : field to use for USER table"
    tmp_text += "\n           ex : 'login'"
    tmp_text += "\n       - user_justify      : length for user field"
    tmp_text += "\n           ex : 10"
    tmp_text += "\n       - level             : log severity"
    tmp_text += "\n           ex : 'DEBUG'"
    tmp_text += "\n       - console           : duplicate log message with 'puts'"
    tmp_text += "\n           ex : true"
    tmp_text += "\n       - level_model       : level for log using CorssTable module"
    tmp_text += "\n           ex : 3"
    tmp_text += "\n       - log_to            : table to put all messages into a table with a creation automatic in the database"
    tmp_text += "\n           ex : 'table'"
    tmp_text += "\n       - scope             : scope for tactilog module (ENV and/or MODEL and/or CONTROLLER)"
    tmp_text += "\n           ex : 'ENV:development,MODEL:[ALL],CONTROLLER:[ALL]'"
    tmp_text += "\n           ex : 'ENV:nothing' to disable 'Tactilog'"
    tmp_text += "\n    The constant list : "
    tmp_text += "\n       - prefix  : prefix of message"
    tmp_text += "\n       - level   : log level"
    tmp_text += "\n       - user    : user if connected"
    tmp_text += "\n       - class   : model or controller name "
    tmp_text += "\n       - year    : year of date"
    tmp_text += "\n       - month   : month of date"
    tmp_text += "\n       - day     : day of date"
    tmp_text += "\n       - time    : time"
    tmp_text += "\n       - milli   : milli-second of the time"
    tmp_text += "\n       - pid     : process id"
    tmp_text += "\n       - client  : client IP"
    tmp_text += "\n       - logid   : a log id is create for each log assign to a environment, a model or a controller"
    tmp_text += "\n       - timing  : timing between current line and previous line for a same logid"
    tmp_text += "\n       - env     : environment name"
  end
end