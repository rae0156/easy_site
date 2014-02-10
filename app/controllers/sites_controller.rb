class SitesController < ApplicationController
  
  def index

    @es_theme_name = "theme" + rand(1..6).to_s
    @es_template_name = "template" + rand(1..6).to_s 

  end
  
end
