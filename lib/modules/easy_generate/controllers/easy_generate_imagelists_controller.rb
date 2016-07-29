# encoding: UTF-8

class EasyGenerateImagelistsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['EasyGenerateImagelist','EasyGenerateImagelistDetail']
                       }
    super
  end 

  
end
