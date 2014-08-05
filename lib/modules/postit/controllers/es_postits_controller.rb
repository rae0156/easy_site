# encoding: UTF-8

class EsPostitsController < DynamicController

  has_es_interface_controllers

  def initialize()
    @controller_setup={:instance_name => 'Post it'}
    super
  end 


end
