# encoding: UTF-8

class EsAbility < ActiveRecord::Base

  belongs_to :es_role    
  acts_as_dynamic_model 
  
end