# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
EasySite::Application.initialize!

Rails.application.config.default_site     = EsSite.first(:conditions=>{:set_as_default => 'Y'}).id
Rails.application.config.current_template = ""
Rails.application.config.current_theme    = ""
