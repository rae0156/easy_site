# encoding: UTF-8

class EsRole < ActiveRecord::Base

  has_and_belongs_to_many :es_users
  belongs_to :es_category    
  
end