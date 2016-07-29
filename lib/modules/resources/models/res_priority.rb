# encoding: UTF-8
class ResPriority < ActiveRecord::Base
  has_es_interface_models
  acts_as_multi_site

  has_many :res_actions
  has_many :res_resources

  acts_as_dynamic_model([
                          {:name              => "code",
                           :label_name        => "Code",
                           :column_name       => "Code",
                           :sort              => true,
                           :field_key         => true,
                           :mandatory         => true,
                           :upper_case        => true,
                           :order             => 1
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :order             => 2
                          }, 
                          {:name              => "type_priority",
                           :label_name        => "Type de priorité",
                           :column_name       => "Type de priorité",
                           :mandatory         => true,
                           :type              => "list",
                           :value_list_method => "list_type_priority",
                           :order             => 3
                          }, 
                          {:name              => "color",
                           :label_name        => "Couleur",
                           :column_name       => "Couleur",
                           :type              => 'color',
                           :order             => 4  
                          }, 
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order             => 5  
                          }, 
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :dynamic_search_exists => false, 
                          :instance_name => "Priorité",
                          :default_sort => 'sequence'
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Priorité".trn,
                  :process_label      => "Changement manuel".trn



  def list_type_priority
    [["Action".trn,"A"],["Ressource".trn,"R"]]
  end

  def get_code_text
    text = self.code 
    text += " - #{self.description}" unless self.description.blank?
  end

  def next
    elem = self.class.where(["type_priority = ? AND sequence > ?",self.type_priority,self.sequence]).order("sequence asc")
    return elem.first
  end

  def previous
    elem = self.class.where(["type_priority = ? AND sequence < ?",self.type_priority,self.sequence]).order("sequence desc")
    return elem.first
  end

end
