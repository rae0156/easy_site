# encoding: UTF-8
class EsMenusController < DynamicController

   def initialize()
    #@setup_controller={:delete_multi => false #, 
                          #:list_options => [ 
                          #                  {:text => "Rôles".trn,:controller => "es_menus", :action => "associate",:params => {:model => 'EsRole'}, :image_file => "appli/setup_48.png"}
                          #                 ], 
                          #:associations => { 
                          #                  :esrole => {:text => "Rôles".trn, :field_list => "name,description", :field_to_display => "name"}
                          #                 } 
    #                  }
#    @columns_screen = [{:name => "es_category_id",
#                        :display_list => false},
#                       {:name => "parent_id",
#                        :display_list => false},
#                       {:name => "link_params",
#                        :display_list => false},                                              
#                      ]

    @controller_link_to={
                          :esrole=> {:title => "Droits utilisateurs pour les menus",:description=>"",:query=>"",:query_link=>"",:query_enabled_ids=>["link_type=? and all_roles=?","link","N"],:column=> "name,description",:column_link=> "name,description"}
                        }
    super
  end 


end
