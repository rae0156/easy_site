# encoding: UTF-8 

class ActionTypeParam < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to   :action_type 

private

end