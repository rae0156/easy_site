# encoding: UTF-8

class EsSitesController < ApplicationController
  
  def change_default_site
    change_site_number(params[:site][:id], self.current_user)
    self.current_user = nil

    respond_to do |format|
      format.html {redirect_to :back} 
#      format.js {render inline: "location.reload();"}
      format.js {render inline: "location = '#{root_url}';"}
    end
  end
end
