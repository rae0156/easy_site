# encoding: UTF-8

class MenuSub < ActiveRecord::Base
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
                           :mandatory         => true,
                           :field_key_scope   => "parent_id",
                           :order             => 2
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :order             => 3
                          }, 
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order              => 4,
                           :display_edit      => false,
                           :display_new       => false,
                           :display_show      => false
                          }
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:link_type => 'submenu',:all_roles => 'Y'}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :instance_name => "Sous menu"

                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name, :es_site => :code  },
                  :model_audit_label  => "Sous menu".trn,
                  :process_label      => "Changement manuel".trn

end