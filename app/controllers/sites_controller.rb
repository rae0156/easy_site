class SitesController < ApplicationController
  
  def index

    @es_theme_name = "theme" + rand(1..6).to_s
    template_names = EsTemplate.all.collect(&:name)
    if template_names.length == 0 
      @es_template_name = "test" 
    else
      @es_template_name = template_names[rand(0..template_names.length-1)] 
    end

  end
  
end
