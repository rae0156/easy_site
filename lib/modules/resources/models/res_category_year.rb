# encoding: UTF-8
class ResCategoryYear < ActiveRecord::Base
  self.table_name = "res_categories"
  has_es_interface_models
  
  acts_as_multi_site

  acts_as_dynamic_model([
                          {:name              => "name",
                           :label_name        => "Année",
                           :column_name       => "Année",
                           :sort              => true,
                           :field_key         => true,
                           :field_key_scope   => "parent_id",
                           :mandatory         => true,
                           :order             => 1
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :order             => 2
                          }, 
                          {:name              => "actif",
                           :label_name        => "Activé",
                           :column_name       => "Activé",
                           :order             => 3
                          } 
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :children_exists => true,
                          :instance_name => "Année des catégories"
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Catégorie de ressources".trn,
                  :process_label      => "Changement manuel".trn

  validate :valid_category
  
private
  def valid_category
    errors.add(:name,"Le champs 'Année' doit commencer par une année".trn) if self.name.to_i == 0
  end
  
  
end
