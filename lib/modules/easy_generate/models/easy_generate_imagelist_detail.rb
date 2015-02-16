# encoding: UTF-8

class EasyGenerateImagelistDetail < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category
  acts_as_dynamic_model([
                          {:name              => "parent_id",
                           :label_name        => "Code liste",
                           :column_name       => "Code liste",
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
                           :order             => 4
                          }, 
                          {:name              => "dummy_1",
                           :type              => "separate",
                           :order             => 5
                          }, 
                          {:name              => "path",
                           :type              => "link", 
                           :label_name        => "Lien image internet",
                           :column_name       => "Lien image internet",
                           :valid_inter_field => [{:name => 'reference',:type => 'only_one'}],
                           :display_list      => false, 
                           :order             => 6
                          }, 
                          {:name              => "dummy_2",
                           :type              => "info",
                           :info              => "Ou",
                           :order             => 7
                          }, 
                          {:name              => "reference",
                           :type              => "file", 
                           :option_file       => "public;/upload/content;jpg,jpeg,png,gif,bmp,[DIR],[EMPTY]", 
                           :label_name        => "Fichier image",
                           :column_name       => "Fichier image",
                           :display_list      => false, 
                           :order             => 8
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
                          :fixed_attributes => {:media_type => 'image'}, 
                          :fixed_attributes_tree => {:media_type => ['image','image_list']}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :instance_name => "Images d'une liste"
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Image d'une liste".trn,
                  :process_label      => "Changement manuel".trn

end