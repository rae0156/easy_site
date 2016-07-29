# encoding: UTF-8

class MenuNavigationsController < EsMenusController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['MenuNavigation',['MenuElement','MenuDetail','MenuSep','MenuDetailActCtrl']]
                       }
    super
  end 
  
end
