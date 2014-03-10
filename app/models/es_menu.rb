# encoding: UTF-8

class EsMenu < ActiveRecord::Base

  belongs_to :es_site
  belongs_to :es_category  

  acts_as_dynamic_model
    
end