# encoding: UTF-8

class EsContent < ActiveRecord::Base

  EDITABLE_CONTENT_TYPES  = ["free"]
  CONTENT_TYPES_MODULE    = "module"
  CONTENT_TYPES           = ["module","free"]

  has_many :es_content_details, :order => "sequence"
  has_many :es_parts
  acts_as_dynamic_model 

  def compress_detail
    self.es_content_details.each_with_index do |l,i|
      l.update_attribute("sequence",i+1)
    end
  end


  def used?
    return self.es_parts.size > 0
  end

end