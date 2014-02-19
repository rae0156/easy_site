# Be sure to restart your server when you modify this file.

    #session store in db    
    EasySite::Application.config.session_store :active_record_store, key: '_easy_site_session'
    ActiveRecord::SessionStore.session_class = EsSession
    ActiveRecord::SessionStore::Session.table_name = 'es_sessions'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# EasySite::Application.config.session_store :active_record_store
