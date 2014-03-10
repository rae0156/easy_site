# encoding: UTF-8

class EsLanguage < ActiveRecord::Base

  belongs_to :es_category
  acts_as_dynamic_model 
  
end