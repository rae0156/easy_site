# encoding: UTF-8

class EsSitesController < ApplicationController
  
  def change_default_site
    Rails.application.config.default_site =params[:site][:id]
    reset_session unless current_user.blank?
    self.current_user = nil

    respond_to do |format|
      format.html {redirect_to :back} 
#      format.js {render inline: "location.reload();"}
      format.js {render inline: "location = '#{root_url}';"}
    end
  end
end
