# encoding: UTF-8

class EsSitesController < ApplicationController
  
  def change_default_site
    session[:current_site_id] =params[:site][:id]
    EsSite.current_site_id=session[:current_site_id]
    reset_session unless current_user.blank?
    self.current_user = nil

    respond_to do |format|
      format.html {redirect_to :back} 
#      format.js {render inline: "location.reload();"}
      format.js {render inline: "location = '#{root_url}';"}
    end
  end
end
