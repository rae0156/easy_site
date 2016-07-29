# encoding: UTF-8

class EasyGenerateAddressesController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Adresses'}
    super
  end 

  
end
