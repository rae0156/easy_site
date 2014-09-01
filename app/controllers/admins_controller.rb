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
      Rails.application.config.current_template = template_to.name
      redirect_to :action => "config_template"
    end
  
    def config_theme
      @theme = EsTheme.find_by_file(Rails.application.config.current_theme).code
    end

    def save_theme
      theme_from = EsTheme.find_by_file(Rails.application.config.current_theme)
      theme_to = EsTheme.find_by_code(params[:admin][:theme])
      EsPage.where(:es_theme_id => theme_from.id).each do |page|
        page.update_attribute(:es_theme_id,theme_to.id)
      end
      Rails.application.config.current_theme = theme_to.file
      redirect_to :action => "config_theme"
    end

    def config_page
      es_content = EsContent.find_by_name("principal")
      @content_detail_id = !es_content.blank? && !es_content.es_content_details.find_by_sequence(1).blank? ? es_content.es_content_details.find_by_sequence(1).id : 0
      @content_tiny = @content_detail_id.blank? ? "" : EsContentDetail.find_by_id(@content_detail_id.to_i).content.html_safe
      respond_to do |format|
        format.html {} 
        format.js {
          @element_id, @partial = ['selection_div','content_div'], ['tinymce/selection','tinymce/content']
          render 'shared/replace_content'
        }
      end
  
    end  
  
    def test_tinymce        
      escontent = EsContentDetail.find_by_id(params[:content_detail_id])
      @content_detail_id = params[:content_detail_id]
      if escontent && params[:id_button]=="sauver_tinymce"
        escontent.update_attribute("content",params[:tinymce_exemple]) 
        @content_tiny = escontent.content.html_safe
      else
        @content_tiny = params[:tinymce_exemple].html_safe
      end
      respond_to do |format|
        format.json {
          render :json => {:result => @content_tiny}
        }
      end
    end

  
end

