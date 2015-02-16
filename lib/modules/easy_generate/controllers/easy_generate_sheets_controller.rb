# encoding: UTF-8

class EasyGenerateSheetsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Feuilles'}
    @columns_screen = []
    super
  end 
  
end
