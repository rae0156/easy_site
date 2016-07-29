# encoding: UTF-8

class EasySystemsController < ApplicationController

  has_es_interface_controllers
  

  def create_super_admin
    redirect_to :controller => "admins", :action => "create_super_admin"
  end

  def site_list
    redirect_to :controller => "admins", :action => "admin_site"
  end

  def init_admin_template
    redirect_to :controller => "admins", :action => "reset_template"
  end

  def init_rails_var
    redirect_to :controller => "admins", :action => "init_workspace"
  end

  def site_wizard
    redirect_to :controller => "es_wizards", :action => "execute", :name => "site"
  end

  def change_template
    redirect_to :controller => "admins", :action => "config_template"
  end

  def change_theme
    redirect_to :controller => "admins", :action => "config_theme"
  end

  def setup_list
    redirect_to :controller => "es_setups", :action => "list"
  end

  def user_profil
    redirect_to :controller => "es_users", :action => "profile"
  end

  def user_password
    redirect_to :controller => "es_users", :action => "password"
  end

  def user_mail
    redirect_to :controller => "es_users", :action => "mail"
  end

  def user_disconnect
    redirect_to :controller => "es_users", :action => "logout"
  end

  def user_connect
    redirect_to :controller => "es_users", :action => "login"
  end

  def user_password_lost
    redirect_to :controller => "es_users", :action => "password_lost"
  end

  def user_signin
    redirect_to :controller => "es_users", :action => "new_user"
  end

end
