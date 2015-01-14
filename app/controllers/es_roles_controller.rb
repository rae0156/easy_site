class EsRolesController < DynamicController

   def initialize()
    @setup_controller={:delete_multi => false}
    super
  end 


end
