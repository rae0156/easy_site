# encoding: UTF-8

class EasyGenerateJsFilesController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Fichier JavaScript'}
    super
  end 
  
end
