# encoding: UTF-8

class EsStatus < ActiveRecord::Base

  has_many :es_articles
  belongs_to :es_category
    
end