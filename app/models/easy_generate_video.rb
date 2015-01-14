# encoding: UTF-8

class EasyGenerateVideo < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category
  acts_as_dynamic_model([
                          {:name              => "name",
                           :label_name        => "Code",
                           :column_name       => "Code",
                           :field_key         => true,
                           :mandatory         => true
                          }, 
                          {:name              => "title",
                           :label_name        => "Titre",
                           :column_name       => "Titre",
                           :mandatory         => true
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description"
                          }, 
                          {:name              => "path",
                           :label_name        => "Lien vidéo internet",
                           :column_name       => "Lien vidéo internet"
                          }, 
                          {:name              => "reference",
                           :label_name        => "Fichier vidéo",
                           :column_name       => "Fichier vidéo"
                          }       
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:media_type => 'video', :sequence => 1}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => false, 
                          :parent_exists => false
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Vidéo".trn,
                  :process_label      => "Changement manuel".trn

end