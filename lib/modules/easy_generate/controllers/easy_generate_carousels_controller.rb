# encoding: UTF-8

class EasyGenerateCarouselsController < EsMediaFilesController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['EasyGenerateCarousel','EasyGenerateCarouselDetail']
                       }
                       
    @columns_screen = []
    super
  end 
  
end
