# encoding: UTF-8

class EsWizard < ActiveRecord::Base
  has_many :es_wizard_details, :order => "sequence"
 
  attr_accessible :name, :description, :wizard_type

  acts_as_multi_site
 
end