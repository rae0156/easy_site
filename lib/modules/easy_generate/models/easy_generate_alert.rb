# encoding: UTF-8

class EasyGenerateAlert < ActiveRecord::Base
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
                          {:name              => "reference",
                           :label_name        => "Sorte d'alerte",
                           :column_name       => "Sorte d'alerte",
                           :value_list        => "alert-success,alert-info,alert-warning,alert-danger",
                           :mandatory         => true
                          }       
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:media_type => 'alert', :sequence => 1}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => false, 
                          :parent_exists => false
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Alerte".trn,
                  :process_label      => "Changement manuel".trn


end