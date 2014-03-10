# encoding: UTF-8

class EsController < ActiveRecord::Base

  acts_as_dynamic_model 

  def self.must_sign?(name)
    controller = self.find_by_name(name)
    return controller ? controller.must_sign? : true
  end
  
  def must_sign?
    self.signed=='Y'
  end
  
end