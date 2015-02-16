# encoding: UTF-8

class EasyGenerateVideo < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category
  acts_as_dynamic_model([
                          {:name              => "name",
                           :label_name        => "Code",
                           :column_name       => "Code",
                           :order             => 1,
                           :field_key         => true,
                           :field_key_scope   => "media_type",
                           :mandatory         => true
                          }, 
                          {:name              => "title",
                           :label_name        => "Titre",
                           :column_name       => "Titre",
                           :order             => 2,
                           :mandatory         => true
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
                          {:name               => "path",
                           :type               => "link", 
                           :label_name         => "Lien vidéo internet",
                           :column_name        => "Lien vidéo internet",
                           :valid_inter_field  => [{:name => 'reference',:type => 'only_one'}],
                           :order              => 5
                          }, 
                          {:name              => "dummy_2",
                           :type              => "info",
                           :info              => "Ou",
                           :order             => 6
                          }, 
                          {:name               => "reference",
                           :type               => "file", 
                           :option_file        => "public;/upload/content;avi,mkv,wmv,[DIR],[EMPTY]", 
                           :label_name         => "Fichier vidéo",
                           :column_name        => "Fichier vidéo",
                           #:valid_inter_field  => [{:name => 'path',:type => 'only_one'}],
                           :order              => 7
                          }, 
                          {:name              => "dummy_3",
                           :type              => "separate",
                           :order             => 8
                          }, 
                          {:name              => "width",
                           :label_name        => "Largeur en pixel",
                           :column_name       => "Largeur en pixel",
                           :column_text       => "En pixel",
                           :order             => 9
                          }, 
                          {:name              => "height",
                           :label_name        => "Hauteur en pixel",
                           :column_name       => "Hauteur en pixel",
                           :column_text       => "En pixel",
                           :order             => 10
                          }                                                           
                        ],
                        { :only_field_defined     =>true, 
                          :audit_model            =>false, 
                          :fixed_attributes       => {:media_type => 'video', :sequence => 1}, 
                          :dynamic_search_exists  => false, 
                          :sequence_exists        => false, 
                          :parent_exists          => false
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Vidéo".trn,
                  :process_label      => "Changement manuel".trn

end