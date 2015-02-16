# encoding: UTF-8

class EasyGenerateSheet < ActiveRecord::Base
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
                           :label_name        => "Texte",
                           :column_name       => "Texte",
                           :type              => "text",
                           :order             => 3
                          }
                        ],
                        { :only_field_defined     =>true, 
                          :audit_model            =>false, 
                          :fixed_attributes       => {:media_type => 'sheet', :sequence => 1}, 
                          :dynamic_search_exists  => false, 
                          :sequence_exists        => false, 
                          :parent_exists          => false
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Feuille".trn,
                  :process_label      => "Changement manuel".trn

end