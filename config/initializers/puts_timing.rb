
module Kernel
  PUTS_TIMING_ACTIVE = false          unless defined? PUTS_TIMING_ACTIVE
  PUTS_TIMING_MODES  = ["ADD_TO_LOG"] unless defined? PUTS_TIMING_MODES

  if PUTS_TIMING_ACTIVE==true
    LIMIT_OF_TIMING = 1.0
    PUTS_TIMING_MODES = [PUTS_TIMING_MODES.to_s] unless PUTS_TIMING_MODES.is_a?(Array)
    
    @@putst_last_time_g = nil
    @putst_last_time    = nil
    alias :old_puts :puts
  end
  
  def puts(message,code="")
    
    
    if PUTS_TIMING_MODES.include?('TIMING')
      long_g = !@@putst_last_time_g.blank? && @putst_last_time.blank? && (Time.now - @@putst_last_time_g) >= 3.0
      long = !@putst_last_time.blank? && (Time.now - @putst_last_time) >= LIMIT_OF_TIMING    
  
      tmp_timing_g = @@putst_last_time_g.blank? ? "" : "(#{(Time.now - @@putst_last_time_g).round(3).to_s})"  
      tmp_timing   = @putst_last_time.blank? ? "" : "(#{(Time.now - @putst_last_time).round(3).to_s})"  
      
      code = (code.blank? ? caller.first.split('/').last.split(':')[0..1].join(':') : "[#{code}]"[0..19])
      milli = (DateTime.now.strftime("%N").to_i / 1000000)
      warning = (long ? "<W>" : "").ljust(3," ")
  
      text_a = []
      text_a << "   ----" if long_g
      pre_message = "#{warning} #{tmp_timing_g.ljust(9," ")} <#{Time.now.strftime("%H:%M:%S")} #{milli.to_s.rjust(3," ")}> #{code.ljust(45,".")}  " 
      if message.index(10.chr).nil?
        text_a << "#{pre_message}#{message}"     
      else
        message.split(10.chr).each do |m|
          text_a << "#{pre_message}#{m}"     
        end
      end
      tmp_message = *text_a 
    else
      tmp_message = message  
    end

    old_puts tmp_message

    if PUTS_TIMING_MODES.include?('ADD_TO_LOG')
      Rails.logger.info tmp_message      
    end


    @putst_last_time  = Time.now
    @@putst_last_time_g = @putst_last_time 

  end  if PUTS_TIMING_ACTIVE==true 
  
  puts "Puts Timing function is activated" if PUTS_TIMING_ACTIVE==true
  
end
