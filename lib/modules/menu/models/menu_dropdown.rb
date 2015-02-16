# encoding: UTF-8

class MenuDropdown < ActiveRecord::Base
  self.table_name = "es_menus"

  belongs_to :es_site
  belongs_to :es_category  
  has_and_belongs_to_many :es_roles, :join_table => 'es_menus_es_roles', :foreign_key => 'es_menu_id'

  acts_as_dynamic_model([
                          {:name              => "name",
                           :label_name        => "Code menu",
                           :column_name       => "Code menu",
                           :field_key         => true,
                           :field_key_scope   => "parent_id",
                           :mandatory         => true
                          },
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :mandatory         => false
                          }
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:link_type => 'dropdown', :sequence => 1}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :instance_name => 'Menus déroulant'

                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name, :es_site => :code  },
                  :model_audit_label  => "Menu déroulant".trn,
                  :process_label      => "Changement manuel".trn

end