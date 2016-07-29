# encoding: UTF-8

class MenuSheetsController < EsMenusController

   def initialize()
    @setup_controller={:delete_multi => false,
                       :max_level => 5,
                       :model_level => ['MenuSheet',['MenuElement','MenuSub','MenuDetailSheet','MenuSep']]
                       }
    super
  end 
    
end
