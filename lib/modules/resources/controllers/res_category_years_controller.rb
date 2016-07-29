# encoding: UTF-8

class ResCategoryYearsController < DynamicController

  has_es_interface_controllers

   def initialize()
    @controller_link_to={}
    @setup_controller={:delete_multi => false,
                       :max_level => 2,
                       :model_level => ['ResCategoryYear',['ResCategory']]
                       }
    super
  end 

end
