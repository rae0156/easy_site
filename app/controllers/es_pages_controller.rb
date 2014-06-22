# encoding: UTF-8

class EsPagesController < DynamicController

   def initialize()
    @controller_setup={:delete_multi => false,:instance_name => 'Accès aux pages'}
    @columns_screen = [{:name => "action",
                        :link_update => true,
                        :column_name => "Action",
                        :column_text => "[ALL] = toutes les actions",
                        :label_name => "Action" },
                       {:name => "es_theme_id",
                        :column_name => 'Thême',
                        :label_name => 'Thême',
                        :model_linked_field => 'code' },
                       {:name => "controller",
                        :column_name => 'Controlleur',
                        :column_text => "[ALL] = tous les controlleurs",
                        :label_name => 'Controlleur' },
                       {:name => "es_template_id",
                        :column_name => 'Template',
                        :label_name => 'Template' },
                       {:name => "flag_admin",
                        :display_list => false,
                        :column_name => 'Administrateur?',
                        :label_name => 'Administrateur?' },
                       {:name => "flag_connection",
                        :display_list => false,
                        :column_name => 'Affichage de la connexion',
                        :label_name => 'Affichage de la connexion' },
                       {:name => "signed",
                        :display_list => false,
                        :column_name => "Besoin d'être connecté",
                        :label_name => "Besoin d'être connecté" },
                      ]
    super
  end 


end
