# Load the rails application

require File.expand_path('../application', __FILE__)


# Initialize the rails application
Rails.application.config.default_site             = 0
Rails.application.config.current_template         = ""
Rails.application.config.current_theme            = ""
Rails.application.config.default_locale_easysite  = :fr
Rails.application.config.translation_mode         = ''    
EasySite::Application.initialize!


init_workspace_easysite
#keep also : init_workspace_easysite in es_utils


#Ne pas bouger d'ici
  ActionMailer::Base.smtp_settings = {  
    :address              => EsSetup.get_setup("mail_serveur_adresse"),  
    :port                 => EsSetup.get_setup("mail_serveur_port"),  
    :domain               => EsSetup.get_setup("site_web"),  
    :user_name            => EsSetup.get_setup("mail_serveur_utilisateur"),  
    :password             => EsSetup.get_setup("mail_serveur_mot_de_passe"),
    :authentication       => "plain",
    :enable_starttls_auto => true,
    :openssl_verify_mode  => 'none'
  }  
  

require "#{Rails.root}/lib/modules/load_modules.rb" if File.exist?( "#{Rails.root}/lib/modules/load_modules.rb")