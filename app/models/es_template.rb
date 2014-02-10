# encoding: UTF-8

class EsTemplate < ActiveRecord::Base

  has_many :es_parts
  belongs_to :es_category
    
  attr_accessible :name, :description, :es_category_id
    
end