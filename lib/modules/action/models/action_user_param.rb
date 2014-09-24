# encoding: UTF-8 

class ActionUserParam < ActiveRecord::Base

  has_es_interface_models

  belongs_to :action_user 
  belongs_to :action_type_param 

  attr_accessible :action_user_id, :action_type_param_id, :value

end