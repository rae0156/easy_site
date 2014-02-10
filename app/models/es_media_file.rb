# encoding: UTF-8

class EsMediaFile < ActiveRecord::Base
  self.columns.each { |c| attr_accessible c.name.to_sym}

  acts_as_tree :order => "sequence"

  belongs_to :es_category
  

end