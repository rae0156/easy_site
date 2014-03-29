# encoding: UTF-8

class EsTemplate < ActiveRecord::Base

  has_many :es_pages
  has_many :es_parts
  belongs_to :es_category
  acts_as_dynamic_model 
    
end