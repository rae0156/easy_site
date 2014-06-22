class EsRolesController < DynamicController

   def initialize()
    @controller_setup={:delete_multi => false}
    super
  end 


end
