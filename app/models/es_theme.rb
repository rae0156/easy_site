# encoding: UTF-8

class EsTheme < ActiveRecord::Base

  has_many :es_pages

  acts_as_dynamic_model 

end