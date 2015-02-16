# encoding: UTF-8

class MenuVerticalsController < EsMenusController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 5,
                       :model_level => ['MenuVertical',['MenuElement','MenuSub','MenuDetail','MenuSep','MenuDetailActCtrl']]
                       }
                       
    @columns_screen = []
    super
  end 
  
end
