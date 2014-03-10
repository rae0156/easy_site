# encoding: UTF-8

class EsContent < ActiveRecord::Base

  has_many :es_content_details
  has_many :es_parts
  acts_as_dynamic_model 

end