# encoding: UTF-8

class ResProductsController < DynamicController

  has_es_interface_controllers

   def initialize()
    @controller_link_to={}
    @setup_controller={:delete_multi => false}
    super
  end 

end
