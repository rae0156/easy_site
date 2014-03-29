class AdminsController < ApplicationController
    self.before_filter :authenticate_user 
  
private

  def authenticate_user
      self.authenticate_es_user! if EsController.must_sign?(controller_name) 
  end    

end

