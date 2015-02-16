# encoding: UTF-8

class EasyGenerateCollapseDetail < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category


  acts_as_dynamic_model([
                          {:name              => "parent_id",
                           :label_name        => "Code type dépliable",
                           :column_name       => "Code type dépliable",
                           :display_list      => false, 
                           :order             => 1
                          },       
                          {:name              => "name",
                           :label_name        => "Code",
                           :column_name       => "Code",
                           :sort              => false,
                           :field_key         => true,
                           :mandatory         => true,
                           :order             => 2
                          }, 
                          {:name              => "title",
                           :label_name        => "Titre",
                           :column_name       => "Titre",
                           :mandatory         => true,
                           :order             => 3
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :type              => "text", 
                           :order             => 4
                          }, 
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order              => 5,
                           :display_edit      => false,
                           :display_new       => false,
                           :display_show      => false
                          }
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:media_type => 'collapse'}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :instance_name => "Elément d'un type dépliable"
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Type dépliable - Détail".trn,
                  :process_label      => "Changement manuel".trn

end