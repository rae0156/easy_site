# encoding: UTF-8

class EasyGenerateCssFilesController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Fichier CSS'}
    super
  end 
  
end
