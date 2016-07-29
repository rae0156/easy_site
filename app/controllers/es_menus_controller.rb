# encoding: UTF-8
class EsMenusController < DynamicController

   def initialize()
    @controller_link_to={
                          :esrole=> {:title => "Droits utilisateurs pour les menus",:description=>"",:query=>"",:query_link=>"",:query_enabled_ids=>["link_type=? and all_roles=?","link","N"],:column=> "name,description",:column_link=> "name,description"}
                        }
    super
  end 


end
