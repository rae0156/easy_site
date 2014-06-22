# encoding: UTF-8

class EsAbilitiesController < DynamicController

   def initialize()
    @controller_setup={:delete_multi => false,:instance_name => 'Accès aux actions'}
    @columns_screen = [{:name => "action",
                        :column_name => "Liste d'actions",
                        :column_text => "manage = toutes les actions",
                        :label_name => "Liste d'actions" },
                       {:name => "controller",
                        :column_name => 'Liste de controlleurs',
                        :column_text => "all = tous les controlleurs",
                        :label_name => 'Liste de controlleurs' },
                       {:name => "description",
                        :link_update => true},
                       {:name => "include_not_connected",
                        :display_list => false,
                        :column_name => 'Non connectés inclus',
                        :label_name => 'Non connectés inclus' },
                      ]
    @controller_link_to={
                          :esrole=> {:title => "Droits utilisateurs pour les actions",:description=>"",:query=>"",:query_link=>"",:query_enabled_ids=>"",:column=> "description",:column_link=> "name,description"}
                        }
    super
  end 


end
