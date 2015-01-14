class AdminsController < ApplicationController
    self.before_filter :login_required 

    def reset
      redirect_to :action => "save_template", :admin => {:template => 'admin'},:method=> "post"   
    end

    def init_workspace
      init_workspace_easysite      
      redirect_to root_url 
    end

    def config_template
      @template = Rails.application.config.current_template
    end

    def save_template
      template_from = EsTemplate.find_by_name(Rails.application.config.current_template)
      template_to = EsTemplate.find_by_name(params[:admin][:template])
      EsPage.where(:es_template_id => template_from.id).each do |page|
        page.update_attribute(:es_template_id,template_to.id)
      end
      EsPage.all.each do |page|
        page.update_attribute(:es_template_id,template_to.id) if page.es_template.blank?
      end
      Rails.application.config.current_template = template_to.name
      redirect_to :action => "config_template"
    end
  
    def config_theme
      theme = EsTheme.find_by_file(Rails.application.config.current_theme)
      theme = EsTheme.find_by_file("easysite_theme1.css") unless theme
      theme = EsTheme.first unless theme
      theme = EsTheme.new unless theme
      @theme = theme.code
    end

    def save_theme
      theme_from = EsTheme.find_by_file(Rails.application.config.current_theme)
      theme_to = EsTheme.find_by_code(params[:admin][:theme])
      EsPage.where(:es_theme_id => theme_from.id).each do |page|
        page.update_attribute(:es_theme_id,theme_to.id)
      end if theme_from
      
      EsPage.all.each do |page|
        page.update_attribute(:es_theme_id,theme_to.id) if page.es_theme.blank?
      end
      Rails.application.config.current_theme = theme_to.file
      redirect_to :action => "config_theme"
    end

    def load_themes
      EsTheme.load_themes
      redirect_to :action => "config_theme"
    end
      
  
end

