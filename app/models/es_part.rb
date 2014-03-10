# encoding: UTF-8

class EsPart < ActiveRecord::Base
  belongs_to :es_template
  belongs_to :es_content
  belongs_to :es_site
  acts_as_dynamic_model 
  
  
end