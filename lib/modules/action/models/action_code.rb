# encoding: UTF-8 

class ActionCode < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

end