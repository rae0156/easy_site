# encoding: UTF-8

class EsTestsController < DynamicController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'instance test'}
    super
  end 


end
