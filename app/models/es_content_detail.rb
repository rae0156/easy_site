# encoding: UTF-8

class EsContentDetail < ActiveRecord::Base

  belongs_to :es_content
  acts_as_dynamic_model 

end