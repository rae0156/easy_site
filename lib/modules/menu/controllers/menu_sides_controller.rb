# encoding: UTF-8

class MenuSidesController < EsMenusController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['MenuSide',['MenuElement','MenuDetail','MenuSep','MenuDetailActCtrl']]
                       }
                       
    @columns_screen = []
    super
  end 
  
end
