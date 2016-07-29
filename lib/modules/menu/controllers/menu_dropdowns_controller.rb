# encoding: UTF-8

class MenuDropdownsController < EsMenusController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['MenuDropdown',['MenuElement','MenuDetail','MenuSep','MenuDetailActCtrl']]
                       }
    super
  end 
  
end
