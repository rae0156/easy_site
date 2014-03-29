class TinymceController < ApplicationController
#    self.load_and_authorize_resource
    self.before_filter :authenticate_user 
  
  def config_content 
    init_selection(params[:ajax_param] && params[:ajax_param][:selection] ? params[:ajax_param][:selection] : {})
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

private

  def init_selection(options={})
    @content_detail_list = []
    @part_list = []
    @template_list = EsTemplate.all
    @template_id = options[:es_template_id]
    @part_id = ""
    @content_detail_id = ""
    if options[:es_template_id].presence
      template = EsTemplate.find_by_id(options[:es_template_id])
      @part_list = template.es_parts.where(["es_content_id IS NOT NULL AND es_content_id > 0"])
      @part_id = options[:es_part_id] if @part_list.collect(&:id).include?(options[:es_part_id].to_i)
    end
    if options[:es_template_id].presence && options[:es_part_id].presence
      part = EsPart.find_by_id(options[:es_part_id])
      if part.es_content && part.es_content.es_content_details.length>0
        @content_detail_list = part.es_content.es_content_details.where({:editable => 'Y'}).order("sequence") 
        @content_detail_id = options[:es_content_detail_id] if @content_detail_list.collect(&:id).include?(options[:es_content_detail_id].to_i)
      end
    end
    
    
    
  end

  def authenticate_user
      self.authenticate_es_user! if EsController.must_sign?(controller_name) 
  end    

end

