# encoding: UTF-8

class EsSitesController < ApplicationController
  def change_default_site
    Rails.application.config.default_site =params[:site][:id]
    sign_out current_es_user
    current_es_user=nil
    
    respond_to do |format|
      format.html {redirect_to :back} 
      format.js {render inline: "location.reload();"}
    end
  end
end
