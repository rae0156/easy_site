# encoding: UTF-8

class EasyGenerateCitationsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Citations'}
    super
  end 
  
end
