# encoding: UTF-8

class EasyGeneratesController < ApplicationController

  has_es_interface_controllers
  
  def setup_address
    redirect_to :controller => "easy_generate_addresses", :action => "list"
  end

  def setup_alert
    redirect_to :controller => "easy_generate_alerts", :action => "list"
  end

  def setup_blog
    redirect_to :controller => "easy_generate_blogs", :action => "list"
  end

  def setup_breadcrumb
    redirect_to :controller => "easy_generate_breadcrumbs", :action => "list"
  end

  def setup_carousel
    redirect_to :controller => "easy_generate_carousels", :action => "list"
  end

  def setup_citation
    redirect_to :controller => "easy_generate_citations", :action => "list"
  end

  def setup_collapse
    redirect_to :controller => "easy_generate_collapses", :action => "list"
  end

  def setup_image_list
    redirect_to :controller => "easy_generate_imagelists", :action => "list"
  end

  def setup_video
    redirect_to :controller => "easy_generate_videos", :action => "list"
  end

  def setup_sheet
    redirect_to :controller => "easy_generate_sheets", :action => "list"
  end

private  

  def get_lorem_ipsum(options)
    get_template_part("lorem","easy_generates",true)
  end
  
  def get_citation(options)
    @citation = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'citation'",options['code_citation'].presence||''])
    get_template_part("citation","easy_generates",true)
  end
  
  def get_address(options)
    @address = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'address'",options['code_address'].presence||''])
    get_template_part("address","easy_generates",true)
  end
  
  def get_alert(options)
    @alert = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'alert'",options['code_alert'].presence||''])
    get_template_part("alert","easy_generates",true)
  end
  

  def get_blog(options)
    blog = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'blog' and parent_id = 0",options['code_blog'].presence||''])
    @blog =  (!blog.blank? && blog.children.size> 0) ? blog.children : nil 
    get_template_part("blog","easy_generates",true)      
  end
        
  def get_breadcrumb(options)
    breadcrumb = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'breadcrumb' and parent_id = 0",options['code_breadcrumb'].presence||''])
    if !breadcrumb.blank? && breadcrumb.children.size> 0
      @breadcrumb = breadcrumb.children.map{|b| (b.reference.blank? ? b.title : [b.title,b.reference])}
    else
      @breadcrumb = nil
    end 
    get_template_part("breadcrumb","easy_generates",true)      
  end
        
  def get_carousel(options)
    carousel = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'carousel' and parent_id = 0",options['code_carousel'].presence||''])
    @carousel = (!carousel.blank? && carousel.children.size> 0) ? carousel.children : nil 
    get_template_part("carousel","easy_generates",true)      
  end
        
  def get_collapse(options)
    collapse = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'collapse' and parent_id = 0",options['code_collapse'].presence||''])
    @collapse = (!collapse.blank? && collapse.children.size> 0) ? collapse.children : nil 
    get_template_part("collapse","easy_generates",true)      
  end
                
  def get_image_list(options)
    image_list = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'image_list' and parent_id = 0",options['code_image_list'].presence||''])
    @image_list = (!image_list.blank? && image_list.children.size> 0) ? image_list.children : nil 
    get_template_part("image_list","easy_generates",true)      
  end

  def get_video(options)
    @video = EsMediaFile.find(:first,:conditions => ["name=? and media_type = 'video'",options['code_video'].presence||''])
    get_template_part("video","easy_generates",true)
  end

end
