# encoding: UTF-8 

class ActionTypeParam < ActiveRecord::Base

  has_es_interface_models

  belongs_to   :action_type 

private

end