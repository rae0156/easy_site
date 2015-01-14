# encoding: UTF-8

class EasyGenerateVideosController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Vidéos'}
    @columns_screen = []
    super
  end 
  
end
