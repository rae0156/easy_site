# encoding: UTF-8

class EasyGenerateAddressesController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Adresses'}
    @columns_screen = []
    super
  end 

  
end
