class SitesController < ApplicationController

    
  def refresh_page
    respond_to do |format|
      format.html {redirect_to :back} 
      format.js {render inline: "location = '#{root_url}';"}
    end
  end
  
  
end
