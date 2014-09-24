# encoding: UTF-8 

class ActionType < ActiveRecord::Base

  has_es_interface_models

  has_many   :action_users 
  has_many   :action_type_params 

private

end