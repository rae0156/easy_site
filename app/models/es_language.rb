# encoding: UTF-8

class EsLanguage < ActiveRecord::Base

  acts_as_dynamic_model([],{:audit_model=>false}) 

#voir acts_as_audited plus bas. Ne pas le bouger

 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.code
  end

  
  def self.trn(code,code_language=:fr,options={})
    return "" if code.blank?
              
    unless Rails.application.config.translation_mode.blank?
      default_text = ""
      if options[:default].present?
        default_text = options[:default]
        options.delete(:default)
      end
      default_text = (Rails.application.config.translation_mode == 'debug' ? "[[#{code}#{options.blank? ? '' : ']] [[' + options.inspect}]]" : code) if default_text.blank? 
      
      code_db = I18n.transliterate(code).gsub(/[^0-9A-Za-z]/, ' ').squeeze(' ').strip.gsub(' ','_')
  
  #    code_db = code.clone.downcase
  #    [' ','"',"'","{","}","(",")",",",";",".","-"].each do |lettre|
  #      code_db.gsub!(lettre,"_")
  #    end
  
      language = self.where(["es_languages.code = ?",code_db]).first 
  
      text=""
      if language.nil?
        self.create({:code => code_db,:text_fr => code})
      elsif (language.translated == 'Y' || Rails.application.config.translation_mode == 'with_new') && language.respond_to?("text_#{code_language}")
        text = language["text_#{code_language}"]
      end
  
      text = default_text if text.blank?
    else
      text = code
    end
    
    unless options.blank?
      text = text % options
#      options.each do |k,v|
#        text.gsub!("%{" + k.to_s + "}", v.to_s)
#      end
    end

    return text
  end


  acts_as_audited :keep_text          => true,
                :child_attrs => { },
                :model_audit_label  => "Langue".trn,
                :process_label      => "Changement manuel".trn

  
end