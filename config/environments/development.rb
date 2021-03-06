EasySite::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true #false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  #config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.active_record.auto_explain_threshold_in_seconds = 1 # fix error ActionView::Template::Error (Mysql2::Error: Table 'mngtools_easysite.begin' doesn't exist: EXPLAIN BEGIN)

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true #si on remet à false, le tinymce ne fonctionne plus 
  
  # Limit the log lines
  config.log_level = :warn #:info :warn :debug 

  #config.action_mailer.default_url_options = { :host => 'localhost:3005' }

  #gem for dev perfomance
  config.dev_tweaks.autoload_rules do
    keep :all
  
    skip '/favicon.ico'
    skip :assets
    keep :forced
  end
end
