# encoding: UTF-8
class ResWhen < ActiveRecord::Base
  has_es_interface_models
  acts_as_multi_site

  has_many :res_resource_starts, :class_name => "ResResource", :foreign_key => "res_when_start_id"
  has_many :res_resource_ends, :class_name => "ResResource", :foreign_key => "res_when_end_id"

  acts_as_dynamic_model([
                          {:name              => "name",
                           :label_name        => "Nom",
                           :column_name       => "Nom",
                           :sort              => true,
                           :field_key         => true,
                           :mandatory         => true,
                           :upper_case        => false,
                           :order             => 1
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :order             => 2
                          },
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order             => 3  
                          }, 
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :dynamic_search_exists => false, 
                          :instance_name => "Moment",
                          :default_sort => 'sequence'
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Moment".trn,
                  :process_label      => "Changement manuel".trn


end
