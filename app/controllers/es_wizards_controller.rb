# encoding: UTF-8

class EsWizardsController < ApplicationController
    self.before_filter :login_required 

  def execute    
    
    if params[:name].present?
      wizard_name = params[:name]
      code_action = params[:code_action].presence||""
      step        = wizard_name==(session[:wizard].present? && session[:wizard][:name]) ? session[:wizard][:step] : 1
    elsif session[:wizard].present?
      wizard_name = session[:wizard][:name]
      code_action = params[:code_action].presence||"stop"
      step        = session[:wizard][:step]
    else
      wizard_name = ""
      step=0
    end

    case code_action
      when "goto"
        step        = params[:wizard][:selected].to_i if params[:wizard].present? && params[:wizard][:selected].present?
      when "step"
        step        = params[:step].to_i if params[:step].present?
      when "refresh"
        step        = step
      when "nothing"        
        return
      when "stop"
        session.delete(:wizard)
        redirect_to root_url 
        return
      when "previous"
        step -= 1
      when "next"
        step += 1
    end

    wizard = EsWizard.find_by_name(wizard_name)
    
    if wizard      
      wizard_details = wizard.es_wizard_details.find(:all,:order => "sequence asc")
      
      buttons=[]
      if step>0 && step<=wizard_details.count
        wizard_detail = wizard_details[step-1]
        buttons << "stop"
        buttons << "refresh"
        buttons << "goto"
      else
        wizard_detail = nil
        buttons << "stop"
      end
      
      #buttons << "previous" if step>1 && step<=wizard_details.count
      #buttons << "next" if step>=1 && step<wizard_details.count


      self.send(wizard_detail.action, "init") if wizard_detail && self.respond_to?(wizard_detail.action)
      if wizard_detail && lookup_context.find_all('es_wizards/_' + wizard_detail.render_name).any?
        tmp_wizard_detail = wizard_detail.render_name
      else
        tmp_wizard_detail = ""
      end      
      
      session[:wizard] = {:name =>wizard.name,:description => wizard.description,:step =>step,:total_step => wizard.es_wizard_details.count, :button=>buttons,:render_name=> tmp_wizard_detail, :wizard_detail => wizard_detail, :wizard_details => wizard_details.map{|w| [w.description,w.sequence]}}
    else
      flash[:error]="L'assistant '%{name}' n'existe pas".trn(:name => wizard_name)
      redirect_to root_url 
    end    
  end

##############################################################################################
  
  def wizard_choose_musique(code_action="action")
    case code_action
    when "init"
      @musique=Rails.application.config.current_musique.split("/")[-1]
      wizard_musique_preview('init')
    when "action"
      EsTemplate.change_musique(params[:admin][:musique])
      @musique=Rails.application.config.current_musique.split("/")[-1]
      wizard_musique_preview('init')
      render "execute" 
    end
  end
  def wizard_musique_preview(code_action="action")
    case code_action
    when "init"
      @previous_sound=nil
    when "action"
      @previous_sound= params[:ajax_param][:admin][:musique].blank? ? '' : EsSetup.get_setup("répertoire_musique","public/") + params[:ajax_param][:admin][:musique]
      respond_to do |format|
        format.js do 
          @element_id, @partial = 'div_sound', 'shared/sound'
          render 'shared/replace_content'
        end
      end
    end
  end
  
##############################################################################################
  
  def wizard_choose_model(code_action="action")
    case code_action
    when "init"
      @template=Rails.application.config.current_template
      wizard_model_preview("init")
    when "action"
      EsTemplate.change_template(params[:admin][:template])
      @template=Rails.application.config.current_template
      wizard_model_preview("init")
      render "execute" 
    end
  end
  def wizard_model_preview(code_action="action")
    case code_action
    when "init"
      @template_preview=EsTemplate.find_by_name(@template)
    when "action"
      @template_preview=EsTemplate.find_by_name(params[:ajax_param][:admin][:template])
      respond_to do |format|
        format.js do 
          @element_id, @partial = 'div_wizard_model_preview', 'wizard_model_preview'
          render 'shared/replace_content'
        end
      end
    end
  end

##############################################################################################

  def wizard_create_menu(code_action="action")
    case code_action
    when "init"
      @mode_menu ="list"
    when "action"
      respond_to do |format|
        format.html{render "execute"}
        format.js do 
          @element_id, @partial = 'wizard_render', 'wizard_create_menu'
          render 'shared/replace_content'
        end
      end       
    end
  end
  
  def wizard_kind_of_menu
    es_menu = EsMenu.find_by_id(params[:id])
    if es_menu.link_type=='vertical_menu'
      es_menu.update_attributes(:link_type => 'horizontal', :model_type => 'MenuHorizontal')
    elsif es_menu.link_type=='horizontal'
      es_menu.update_attributes(:link_type => 'vertical_menu', :model_type => 'MenuVertical')
    end

    @mode_menu ="list"
    wizard_create_menu
  end


  def wizard_content_menu
    menu = EsMenu.find_by_id(params[:id])
    if menu.link_type == "horizontal" 
      redirect_to :controller => "menu_horizontals", :action => "list", :parent_id => menu.id
    elsif menu.link_type == "vertical_menu" 
      redirect_to :controller => "menu_verticals", :action => "list", :parent_id => menu.id
    end
  end


##############################################################################################

  def wizard_create_page(code_action="action")
    session[:parts_preview]=[]

    case code_action
    when "init"
      @mode_page ="list"
      @model_page_name=""
      #wizard_model_preview("init")
    when "action"
      @model_page_name=params[:admin].presence ? params[:admin][:template] : ""
      #wizard_model_preview("init")
      render "execute" 
    end
  end

  def wizard_cancel_page
    @template = nil
    @mode_page ="list"
    wizard_create_page
  end

  def wizard_edit_page
    @template = EsTemplate.find_by_id(params[:id])
    @mode_page ="new"
    wizard_create_page
  end

  def wizard_new_page
    @template = EsTemplate.new
    @mode_page ="new"
    wizard_create_page
  end

  def wizard_add_page    
    tmp_attr = {:name => params[:template][:name],:description => params[:template][:description],:validated => 'Y',:template_type => "PAGE"}

    if params[:id].presence.blank?
      @template = EsTemplate.new(tmp_attr)
      
      if params[:admin][:template].blank?
        @mode_page ="new"
        @template.errors.add(:base,"Choisissez un modèle de page".trn)
      elsif DynPage.find_by_name(params[:template][:name])
        @mode_page ="new"
        @template.errors.add(:base,"Ce nom de page existe déjà".trn)
      elsif @template.valid?
        es_template_from = EsTemplate.find_by_name(params[:admin][:template])
        @template = es_template_from.deep_clone :include => [:es_template_lines => [:es_template_cols]]
        @template.attributes = tmp_attr
        @template.save
        DynPage.create(:name => @template.name, :description => @template.description, :page_type => 'page', :es_template_id => @template.id)
        @mode_page ="list"      
      else
        @mode_page ="new"
      end
    else
      @template = EsTemplate.find_by_id(params[:id])
      dyn_page = DynPage.find(:first, :conditions => {:name => params[:template][:name], :es_template_id => @template.id })
      @template.attributes = tmp_attr
      if !dyn_page
        @mode_page ="new"
        @template.errors.add(:base,"La page n'a pas été trouvée".trn)
      elsif @template.valid?
        @template.save
        dyn_page.update_attributes({:name => @template.name, :description => @template.description})
        @mode_page ="list"      
      else
        @mode_page ="new"
      end
    end
    
    wizard_create_page
  end
  
  def wizard_content_page
    @template = EsTemplate.find_by_id(params[:id])
    @mode_page = "design"
    wizard_create_page
  end
    
  
  def wizard_destroy_page
    @template = EsTemplate.new
    es_template = EsTemplate.find_by_id(params[:id])
    if es_template
      page = DynPage.where(:name => es_template.name,:es_template_id => es_template.id).first
      page_count = DynPage.where(:es_template_id => es_template.id).all.count
      if (page && page_count > 1) || (!page && page_count > 0)
        @template.errors.add(:base,"Impossible de supprimer le template, car d'autres pages y sont liées".trn)
      else
        es_template.es_template_lines.destroy_all
        es_template.destroy
        page.destroy if page
      end
    end
    params[:admin]={:template=>''}
    @mode_page ="list"
    wizard_create_page
  end
  
  
##############################################################################################
  
  
  def wizard_choose_theme(code_action="action")
    case code_action
    when "init"
      theme = EsTheme.find_by_file(Rails.application.config.current_theme)
      theme = EsTheme.first unless theme
      @theme = theme.code
      wizard_theme_preview("init")
    when "action"
      EsTheme.change_theme(params[:admin][:theme])
      theme = EsTheme.find_by_file(Rails.application.config.current_theme)
      theme = EsTheme.first unless theme
      @theme = theme.code
      wizard_theme_preview("init")
      render "execute" 
    end
  end
  def wizard_theme_preview(code_action="action")
    case code_action
    when "init"
      @theme_preview = ""
    when "action"
      @theme_preview = params[:ajax_param][:admin][:theme]
      respond_to do |format|
        format.js do 
          @element_id, @partial = 'div_wizard_theme_preview', 'wizard_theme_preview'
          render 'shared/replace_content'
        end
      end
    end
  end

##############################################################################################
    
  def wizard_template_content(code_action="action")

    session[:parts_preview]=[]
    case code_action
    when "init"
      @template = EsTemplate.find_by_name(Rails.application.config.current_template)
    when "action"
      @template = EsTemplate.find_by_name(Rails.application.config.current_template)
      render "execute" 
    end    
  end  
    
end

##############################################################################################
