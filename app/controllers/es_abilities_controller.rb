# encoding: UTF-8

class EsAbilitiesController < DynamicController

   def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Accès aux actions'}
    @controller_link_to={
                          :esrole=> {:title => "Droits utilisateurs pour les actions",:description=>"",:query=>"",:query_link=>"",:query_enabled_ids=>"",:column=> "description",:column_link=> "name,description"}
                        }
    super
  end 


end
