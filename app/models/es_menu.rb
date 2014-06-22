# encoding: UTF-8

class EsMenu < ActiveRecord::Base

  belongs_to :es_site
  belongs_to :es_category  
  has_and_belongs_to_many :es_roles

  acts_as_dynamic_model
    
end