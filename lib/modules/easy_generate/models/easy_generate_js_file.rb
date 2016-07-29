# encoding: UTF-8

class EasyGenerateJsFile < ActiveRecord::Base
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
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :order             => 2
                          }, 
                          {:name              => "reference",
                           :type              => "file", 
                           :option_file       => "public/javascripts;/upload/content;js,[EMPTY]", 
                           :label_name        => "Fichier JavaScript",
                           :column_name       => "Fichier JavaScript",
                           :order             => 3
                          }
                        ],
                        { :only_field_defined     =>true, 
                          :audit_model            =>false, 
                          :fixed_attributes       => {:media_type => 'js_file', :sequence => 1}, 
                          :dynamic_search_exists  => false, 
                          :sequence_exists        => false, 
                          :parent_exists          => false
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Fichier JavaScript".trn,
                  :process_label      => "Changement manuel".trn

end