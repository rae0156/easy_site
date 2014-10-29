# encoding: UTF-8 

class ActionScreen < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to :action_user 
  belongs_to :user, :foreign_key => "user_id", :class_name => "EsUser" 

  attr_accessible :action_user_id, :user_id, :x, :y

end