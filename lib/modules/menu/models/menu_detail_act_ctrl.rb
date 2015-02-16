# encoding: UTF-8

class MenuDetailActCtrl < ActiveRecord::Base
  self.table_name = "es_menus"

  belongs_to :es_site
  belongs_to :es_category  
  has_and_belongs_to_many :es_roles, :join_table => 'es_menus_es_roles', :foreign_key => 'es_menu_id'

  acts_as_dynamic_model([
                          {:name              => "parent_id",
                           :label_name        => "Code menu",
                           :column_name       => "Code menu",
                           :display_list      => false, 
                           :order             => 1
                          },       
                          {:name              => "name",
                           :label_name        => "Code",
                           :column_name       => "Code",
                           :sort              => false,
                           :field_key         => true,
                           :field_key_scope   => "parent_id",
                           :mandatory         => true,
                           :order             => 2
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :order             => 3
                          }, 
                          {:name              => "dummy_1",
                           :type              => "separate",
                           :order             => 4
                          }, 
                          {:name              => "controller",
                           :label_name        => "Controller name",
                           :column_name       => "Controller name",
                           :display_list      => false, 
                           :order             => 5
                          }, 
                          {:name              => "action",
                           :label_name        => "Action name",
                           :column_name       => "Action name",
                           :display_list      => false, 
                           :order             => 6
                          }, 
                          {:name              => "dummy_2",
                           :type              => "separate",
                           :order             => 7
                          }, 
                          {:name              => "all_roles",
                           :label_name        => "Accès à tous",
                           :column_name       => "Accès à tous",
                           :display_list      => false, 
                           :order             => 8
                          }, 
                          {:name              => "es_role_ids",
                           :label_name        => "Rôles",
                           :column_name       => "Rôles",
                           :type              => "association",
                           :display_list      => false, 
                           :model_linked_field=> "name",
                           :order             => 9
                          }, 
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order              => 10,
                           :display_edit      => false,
                           :display_new       => false,
                           :display_show      => false
                          }
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:link_type => 'link'}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :children_exists => false,
                          :instance_name => "Point de menu système"
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name, :es_site => :code  },
                  :model_audit_label  => "Point d'un menu".trn,
                  :process_label      => "Changement manuel".trn



end