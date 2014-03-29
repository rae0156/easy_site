# encoding: UTF-8

class EsSite < ActiveRecord::Base
  acts_as_dynamic_model 
  
  def complete_name
    "#{self.code} - #{self.description}"
  end
  
  def self.current
    self.find (Rails.application.config.default_site)
  end
  
end