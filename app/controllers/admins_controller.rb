# encoding: UTF-8

class AdminsController < ApplicationController
    self.before_filter :login_required 

    def shortcut
      esrole = EsRole.find_by_name("superadmin")
      if esrole && esrole.es_users.count > 0
        self.current_user = esrole.es_users.order("id asc").first
        if params[:go_controller].present? && params[:go_action].present?
          tmp_params = {:controller => params[:go_controller], :action => params[:go_action]}
          tmp_params.merge!(params.except(:controller, :action, :go_controller, :go_action))
          redirect_to tmp_params
        else
          redirect_to :controller => :sites, :action => :index
        end
      else
        redirect_to root_url 
      end          
    end


    def create_super_admin
      esrole = EsRole.find_by_name("superadmin")
      if current_user.nil?
        flash[:error]="Vous devez être connecté pour créer le premier super administrateur".trn
        redirect_to root_url 
      elsif esrole
        if esrole.es_users.count>0
          flash[:error]="Il existe déjà un super administrateur".trn
          redirect_to root_url 
        end
      else
        flash[:error]="Le rôle superadmin n'existe pas".trn
        redirect_to root_url 
      end
    end

    def reload_module
      name = File.exist?( "#{Rails.root}/lib/modules/load_modules.rb") ? params[:name].presence : ''
      unless name.blank?
        ModuleLoader.load_all_module(name,true)
        flash[:notice]="Le module '%{module}' est rechargé".trn(:module => name)
      else
        flash[:error]="Ce module n'existe pas ou la gestion des modules n'est pas installée".trn
      end
      redirect_to root_url 
    end

    def save_super_admin
      esrole = EsRole.find_by_name("superadmin")
      if current_user && esrole && !current_user.es_role_ids.include?(esrole.id)
        current_user.es_roles << esrole
        current_user.save
        flash[:notice]="Vous êtes maintenant un super administrateur".trn
      else
        flash[:error]="La création d'un super administrateur a échoué".trn
      end
      redirect_to root_url 
    end

    def admin_site
      sorting :default => "code asc"
      @sites = EsSite.paginate :per_page => 20, :page => params[:page], :order => @sort
      respond_to do |format|
        format.html {} # Do nothing, so Rails will render the view list.rhtml
        format.js do 
          @element_id, @partial = 'list_div', 'list'
          render 'shared/replace_content'
        end
      end
    end

    def change_site
      site_id     = params[:id].presence||0
      site = EsSite.find_by_id(site_id)
      if site
        change_site_number(site_id, self.current_user||EsUser.new)
        self.current_user = nil
        redirect_to root_url 
      else  
        redirect_to :action => "admin_site"
      end      
    end

    def de_activate_site
      site_id     = params[:id].presence||0
      site = EsSite.find_by_id(site_id)
      if site
        if site.active=='Y'
          site.update_attribute('active','N')    
          flash[:notice] = "%{element} a été désactivé.".trn(:element=> site.code)
        else
          site.update_attribute('active','Y')    
          flash[:notice] = "%{element} a été activé.".trn(:element=> site.code)
        end
      end
      redirect_to :action => "admin_site",:page=> params[:page]
    end

    def reset_template
      redirect_to :action => "save_template",:method=> "post"   
    end

    def init_workspace
      init_workspace_easysite      
      redirect_to root_url 
    end

    def config_template
      @template = Rails.application.config.current_template
    end

    def save_template
      if !params[:admin].present?
        params[:admin] = {:template => 'admin'}
        admin=true
      end

      EsTemplate.change_template(params[:admin][:template])

      if admin
        redirect_to root_url
      else
        redirect_to :action => "config_template"
      end
    end
  
    def config_theme
      theme = EsTheme.find_by_file(Rails.application.config.current_theme)
      theme = EsTheme.find_by_file("easysite_theme1.css") unless theme
      theme = EsTheme.first unless theme
      theme = EsTheme.new unless theme
      @theme = theme.code
    end


    def save_theme
      EsTheme.change_theme(params[:admin][:theme])
      redirect_to :action => "config_theme"
    end

    def load_themes
      EsTheme.load_themes
      redirect_to :action => "config_theme"
    end
      
  def destroy_site
      current_site_id = EsSite.current_site_id
      new_site_id     = params[:id].presence||0
      if !new_site_id.blank?  
        es_site = EsSite.find_by_id(new_site_id)    
      else
        es_site = nil
      end
      if es_site
        if es_site.protected=='N'
          flash[:notice]="Le site '%{site}' est supprimé complètement".trn(:site => es_site.description)
          change_site_number(es_site.id, nil)
          EsSite.delete_a_site
          change_site_number(current_site_id, nil)
          init_workspace_easysite      
        else
          flash[:error]="Le site '%{site}' est protégé, il ne peut pas être supprimé".trn(:site => es_site.description)
        end
      else
        flash[:error]="Le site que vous voulez supprimer n'existe pas".trn
      end
      
      redirect_to :action => "admin_site"
    end
  
    def export_to_yaml
      model_name      = params[:model_name].presence||''
      exclude_fields  = (params[:exclude_fields].presence||'').split(',')
      unless model_name.blank?
        EsSite.export_model_to_yaml(model_name,nil,exclude_fields)
        flash[:notice]="Le model '%{model_name}' est exporté en YAML".trn(:model_name => model_name)
      end
      redirect_to root_url 
    end
  
    def new_site
      @site = EsSite.new()
    end
       
    def create_site
      current_site_id = EsSite.current_site_id
      @site = EsSite.new(params[:site])
      if @site.save
        change_site_number(@site.id, nil)
        error_lines = EsSite.create_a_site
        change_site_number(current_site_id, nil)
        init_workspace_easysite
        
        if error_lines.blank?
          flash[:notice]="Le site '%{site}' est créé avec succès".trn(:site => @site.code)
        else
          flash[:notice]="Le site '%{site}' est créé, mais avec certaines erreurs".trn(:site => @site.code)
          flash[:error]=error_lines.join('<BR>').html_safe
        end
        redirect_to :action => "admin_site"
      else
        render :action => 'new_site'
      end
    end
  
    def refresh_site
      current_site_id = EsSite.current_site_id
      id     = params[:id].presence||0
      es_site = EsSite.find_by_id(id)    
      if es_site
        change_site_number(es_site.id, nil)
        error_lines = EsSite.create_a_site('Y')
        change_site_number(current_site_id, nil)
        init_workspace_easysite
        
        if error_lines.blank?
          flash[:notice]="Le site '%{site}' est actualisé avec succès".trn(:site => es_site.code)
        else
          flash[:notice]="Le site '%{site}' est actualisé, mais avec certaines erreurs".trn(:site => es_site.code)
          flash[:error]=error_lines.join('<BR>').html_safe
        end
      else
        flash[:error]="Le site que vous voulez actualiser n'existe pas".trn
      end
      
      redirect_to :action => "admin_site"
    end
  
    def edit_site
      id = params[:id].presence || 0 
      @site = EsSite.find(id)
    end
    
    # Update the Setup in the database -
    def update_site
      @site = EsSite.find_by_id(params[:id])
      if @site.update_attributes(params[:site])
        flash[:notice]="Le site '%{site}' est modifié avec succès".trn(:site => @site.code)
        redirect_to :action => "admin_site"
      else
        render :action => 'edit_site'
      end
    end
 

#    def create_site
#      site_code         = params[:site_code].presence||'code_%{number}'.trn(:number =>DateTime.now.strftime('%Q'))
#      site_description  = params[:site_description].presence||site_code
#      accept_existing   = params[:accept_existing_site].presence||'N'
#      current_site_id = EsSite.current_site_id
#      es_site = EsSite.find_by_code(site_code) 
#      if es_site && accept_existing=='N'
#        flash[:error]="Le site '%{site}' existe déjà".trn(:site => site_code)
#      else           
#        es_site = EsSite.create(:code=> site_code, :description => site_description) if es_site.blank?
#        new_site_id     = es_site.id
#        if !new_site_id.blank? && es_site
#          change_site_number(new_site_id, nil)
#          error_lines = EsSite.create_a_site
#          change_site_number(current_site_id, nil)
#          init_workspace_easysite
#          
#          if error_lines.blank?
#            flash[:notice]="Le site '%{site}' est créé avec succès".trn(:site => es_site.description)
#          else
#            flash[:error]=error_lines.join('<BR>').html_safe
#          end                
#        end
#      end         
#      redirect_to root_url
#    end
    
  
end

