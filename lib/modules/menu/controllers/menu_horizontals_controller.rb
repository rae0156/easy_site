# encoding: UTF-8

class MenuHorizontalsController < EsMenusController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 5,
                       :model_level => ['MenuHorizontal',['MenuElement','MenuSub','MenuDetail','MenuSep','MenuDetailActCtrl']]
                       }
    super
  end 
  
end
