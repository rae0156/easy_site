# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
EasySite::Application.initialize!

Rails.application.config.default_site     = EsSite.first(:conditions=>{:set_as_default => 'Y'}).id
Rails.application.config.current_template = ""
Rails.application.config.current_theme    = ""


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
  

