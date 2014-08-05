class EsMenusController < DynamicController

   def initialize()
    @controller_setup={:delete_multi => false}
    @columns_screen = [{:name => "es_category_id",
                        :display_list => false},
                       {:name => "parent_id",
                        :display_list => false},
                       {:name => "link_params",
                        :display_list => false},                                              
                      ]
    @controller_link_to={
                          :esrole=> {:title => "Droits utilisateurs pour les menus",:description=>"",:query=>"",:query_link=>"",:query_enabled_ids=>["link_type=? and all_roles=?","link","N"],:column=> "name,description",:column_link=> "name,description"}
                        }
    super
  end 


end
