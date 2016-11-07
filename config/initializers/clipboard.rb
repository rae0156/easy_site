# encoding: UTF-8

module ClipboardController
  protected
  def cb_copy(key,value,label="")
    ClipBoard.copy(request.session_options[:id],key,value,label)
  end
  def cb_exist?(key)
    ClipBoard.exist?(request.session_options[:id],key)
  end
  def cb_paste(key)
    ClipBoard.paste(request.session_options[:id],key,true)
  end
  def cb_get(key)
    ClipBoard.paste(request.session_options[:id],key,false)
  end
  def cb_clear
    ClipBoard.clear(request.session_options[:id])
  end
  def cb_log
    ClipBoard.log(request.session_options[:id])
  end
  def cb_view
    ClipBoard.view(request.session_options[:id])
  end

  def cb_get_all_session
    ClipBoard.get_all_session
  end
  
  def cb_clear_all_session
    ClipBoard.clear_all_session
  end
  
end

class ClipBoard
  @@session_clipboard={}

  def self.copy(session_id,key,value,label="")    
    clip_session(session_id)[key]={:value => value, :label => label}
  end  
  
  def self.exist?(session_id,key)    
    return clip_session(session_id)[key].present? ? clip_session(session_id)[key][:label] : nil
  end  
  
  def self.paste(session_id,key,delete=true)    
    return ((delete ? clip_session(session_id).delete(key) : clip_session(session_id)[key])||{})[:value]
  end  

  def self.clear(session_id)
    @@session_clipboard.delete(session_id)
    return nil
  end  

  def self.view(session_id)
    clip_session(session_id)
  end  

  def self.log(session_id)
    puts "================="
    puts "==  Clipboard  =="
    puts "================="
    clip_session(session_id).each do |key,value|
      puts " - #{key} : #{value[:value].inspect}"
    end          
    puts "================="
    puts " "
    return "Voir le résultat dans le log".trn
  end  

  def self.get_all_session
    return @@session_clipboard
  end
  
  def self.clear_all_session
    @@session_clipboard={}
    return nil
  end
  
private
  def self.clip_session(session_id)
    return (@@session_clipboard[session_id]||={})
  end
  
  puts "Clipboard is activated"
  
end
