# encoding: UTF-8

class EsContentDetailParam < ActiveRecord::Base

  belongs_to :es_content_detail
  acts_as_dynamic_model 

end