# encoding: UTF-8

class EasyGenerateBreadcrumbDetail < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category


  acts_as_dynamic_model([
                          {:name              => "parent_id",
                           :label_name        => "Code fil conducteur",
                           :column_name       => "Code fil conducteur",
                           :display_list      => false, 
                           :order             => 1
                          },       
                          {:name              => "name",
                           :label_name        => "Code élément",
                           :column_name       => "Code élément",
                           :sort              => false,
                           :field_key         => true,
                           :mandatory         => true,
                           :order             => 2
                          }, 
                          {:name              => "title",
                           :label_name        => "Libellé",
                           :column_name       => "Libellé",
                           :mandatory         => true,
                           :order             => 3
                          }, 
                          {:name              => "reference",
                           :label_name        => "Url",
                           :column_name       => "Url",
                           :type              => "link", 
                           :order             => 4
                          },
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order              => 5,
                           :display_edit      => false,
                           :display_new       => false,
                           :display_show      => false
                          }
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {:media_type => 'breadcrumb'}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :instance_name => "Element du fil conducteur"
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Fil conducteur - Détail".trn,
                  :process_label      => "Changement manuel".trn

end