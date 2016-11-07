# encoding: UTF-8
class ResProduct < ActiveRecord::Base
  has_es_interface_models
  acts_as_multi_site

  has_many :res_resources
  has_many :res_stocks

  self.per_page = 100

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
                          }
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :dynamic_search_exists => false, 
                          :instance_name => "Produit",
                          :default_sort => 'name'
                        }) 
                        
                        
                        
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Produit".trn,
                  :process_label      => "Changement manuel".trn


end
