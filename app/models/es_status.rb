# encoding: UTF-8

class EsStatus < ActiveRecord::Base

  has_many :es_articles
  belongs_to :es_category
  acts_as_dynamic_model 
    
end