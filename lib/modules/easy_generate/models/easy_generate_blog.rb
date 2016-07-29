# encoding: UTF-8

class EasyGenerateBlog < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category

  acts_as_dynamic_model([
                          {:name              => "name",
                           :label_name        => "Code type blog",
                           :column_name       => "Code type blog",
                           :field_key         => true,
                           :field_key_scope   => "media_type",
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
                          :fixed_attributes => {:media_type => 'blog', :sequence => 1}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :children_exists => true,
                          :instance_name => 'Type blog'

                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Type blog".trn,
                  :process_label      => "Changement manuel".trn

end