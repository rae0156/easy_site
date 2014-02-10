# encoding: UTF-8

class EsArticle < ActiveRecord::Base
  
  belongs_to :es_category
  belongs_to :es_status
  
  
end