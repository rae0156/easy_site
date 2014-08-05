module Kernel
  def log(message, level = ActiveSupport::BufferedLogger::INFO)
    Rails.logger.add level,message
  end  
end

class String
  def is_integer?(length=99)
    if Integer(self) && !self.include?(",") && !self.include?(".")
      self.length <= length
    else
      false
    end 
    rescue 
      return false
  end
end


module ActiveSupport
  require 'date'
  class BufferedLogger
    LOG_LEVEL_MAP = {
      'debug' => ActiveSupport::BufferedLogger::DEBUG,
      'warn'  => ActiveSupport::BufferedLogger::WARN,
      'fatal' => ActiveSupport::BufferedLogger::FATAL,
      'error' => ActiveSupport::BufferedLogger::ERROR,
      'info'  => ActiveSupport::BufferedLogger::INFO
    }


    @setup_log=nil
    @class_name=""
    @timing_log = nil
    @client_ip = ""
    
    def init_log_setup(class_name="")
      @class_name=class_name.downcase
      @setup_log=LogYamlSetup.get_setup(rails_environment,@class_name)
      init_log_file() unless @setup_log.blank?
      @timing_log = Time.now
    end 

    def init_client(client_ip)
      @client_ip = client_ip
    end
    
    def setup_log
      @setup_log
    end

    def add(severity, message = nil, progname = nil, &block)

      init_log_setup if @setup_log.nil? 
      return if @level > severity

      tmp_timing = ((Time.now - @timing_log)).round(3) unless @timing_log.blank?


      @setup_log={} if @setup_log.blank?

      unless @setup_log.blank?
        f_user = ""
        if @setup_log['format'].to_s.include?('%user%') || ((@setup_log['log_to'] || 'table') == 'table')       
          begin
            f_user = User.current_user.send((@setup_log['user_field'] || 'login').to_s)
          rescue
          end
          
        end
        f_user = f_user[0..(@setup_log['user_justify'].to_i - 1)].ljust(@setup_log['user_justify'].to_i," ") if @setup_log['user_justify'].to_s.is_integer?
      end
      
      f_level = {
        0 => "DEBUG",
        1 => "INFO",
        2 => "WARN",
        3 => "ERROR",
        4 => "FATAL"
      }[severity] || "U"

      unless @setup_log.blank?
        tmp_message = @setup_log['format'].to_s
        tmp_message_followed = tmp_message
        { 'prefix' => @setup_log['prefix'].to_s,
          'level' => f_level.ljust(5," "),
          'user' => f_user,
          'class' => (@class_name || ''),
          'year' => Time.now.strftime("%Y"),
          'month' => Time.now.strftime("%m"),
          'day' => Time.now.strftime("%d"),
          'time' => Time.now.strftime("%H:%M:%S"),
          'milli' => DateTime.now.strftime("%N"),
          'pid' => $$.to_s.ljust(6," "),
          'logid' => self.object_id.to_s,
          'timing' => '[TIMLOG]' ,
          'client' => @client_ip.to_s.ljust(15," "),          
          'env' => rails_environment}.each do |key,var|
          tmp_message_followed = tmp_message_followed.gsub("%#{key}%",var)
        end

        tmp_message = tmp_message_followed.gsub("[TIMLOG]",("%8.3f" % tmp_timing)[-8..-1])
        tmp_message_followed = tmp_message_followed.gsub("[TIMLOG]",("%8.3f" % 0)[-8..-1])

      end
      
      message = (message || (block && block.call) || progname).to_s
      
      unless @setup_log.blank?
        complete_message=''
        message.split(10.chr).each do |line|
          tmp_line = (complete_message.blank? ? tmp_message : tmp_message_followed) + ' ' + line
          puts "#{tmp_line}" if @setup_log['console']
          if (@setup_log['log_to'] || 'file') == 'table'
            sql="INSERT INTO tactilogs "
            sql+= "(prefix,level_name,user_name,class_name,milli,pid,timing,env,line,date_time,logid,followed)"
            sql+= " VALUES ('#{@setup_log['prefix'].to_s}','#{f_level}','#{f_user}','#{@class_name.to_s}',#{DateTime.now.strftime("%N").to_i},'#{$$.to_s}',#{tmp_timing.to_f},'#{rails_environment}','#{line.gsub("'","''")}','#{Time.now.strftime("%Y/%m/%d %H:%M:%S")}','#{self.object_id}','#{complete_message.blank? ? 'N' : 'Y'}')"
            ActiveRecord::Base.connection.execute(sql) 
          end

          complete_message += tmp_line + "\n"
        end
        complete_message = tmp_message if complete_message.blank?
      else
        complete_message = message
      end

      complete_message = "#{complete_message}\n" unless complete_message[-1] == ?\n
      @timing_log=Time.now


      if rails_env == '3'
        complete_message.chomp! 
        @log.add(severity, complete_message, progname, &block)
      else      
        buffer << complete_message
        auto_flush
        complete_message
      end
    end

    def reopen(log, level = DEBUG)
      @level         = level
      @buffer        = {}
      @auto_flushing = 1
      if log.respond_to?(:write)
        tmp_log = log
      elsif File.exist?(log)
        tmp_log = open(log, (File::WRONLY | File::APPEND))
        tmp_log.sync = true
      else
        FileUtils.mkdir_p(File.dirname(log))
        tmp_log = open(log, (File::WRONLY | File::APPEND | File::CREAT))
        tmp_log.sync = true
#        @log.write("# Logfile created on %s\n" % [Time.now.to_s])
      end
      
      if rails_env == '3'
        @log = open_logfile tmp_log
      else
        @log = tmp_log
      end
      
    end
    
private
    def rails_env
      (ENV['RAILS_VERSION'].blank? ? Rails::VERSION::STRING : ENV['RAILS_VERSION'])[0]      
    end

    def rails_environment
      rails_env == '3' ? Rails.env : ENV["RAILS_ENV"]
    end


    def init_log_file
      file_name = @setup_log['file'] || "%env%.log"
      { 'year' => Time.now.strftime("%Y"),
        'month' => Time.now.strftime("%m"),
        'day' => Time.now.strftime("%d"),
        'time' => Time.now.strftime("%H:%M:%S"),
        'milli' => DateTime.now.strftime("%N"),
        'class' => (@class_name || ''),
        'env' => rails_environment}.each do |key,var|
        file_name = file_name.gsub("%#{key}%",var)
      end
      self.close      
      self.reopen(Rails.root.join("log",file_name), LOG_LEVEL_MAP[(@setup_log['level'] || 'debug').downcase] )
      
      create_log_table if (@setup_log['log_to'] || 'file') == 'table'
            
    end    

    def create_log_table
      unless ActiveRecord::Base.connection.table_exists? 'tactilogs'
        ActiveRecord::Schema.define do
          create_table :tactilogs do |t|
            t.column :id, :integer
            t.column :prefix, :string, :limit => 200
            t.column :level_name, :string
            t.column :user_name, :string, :limit => 200
            t.column :class_name, :string, :limit => 200
            t.column :date_time, :string
            t.column :milli, :integer
            t.column :pid, :string
            t.column :logid, :string
            t.column :timing, :decimal, {:precision => 20, :scale => 10}
            t.column :env, :string
            t.column :line, :string, :limit => 4000
            t.column :followed , :string
          end
        end
      end
    end
    
    
  end
end



