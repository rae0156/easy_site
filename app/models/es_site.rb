# encoding: UTF-8

class EsSite < ActiveRecord::Base
  acts_as_dynamic_model 
  
  cattr_accessor  :current_site_id
  
  def complete_name
    "#{self.code} - #{self.description}"
  end
  
end