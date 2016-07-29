# encoding: UTF-8
class ResStatus < ActiveRecord::Base
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
                          {:name              => "color",
                           :label_name        => "Couleur",
                           :column_name       => "Couleur",
                           :type              => 'color',
                           :order             => 3  ,
                          }, 
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order             => 4  
                          }, 
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :dynamic_search_exists => false, 
                          :instance_name => "Statut",
                          :default_sort => 'sequence'
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Statut".trn,
                  :process_label      => "Changement manuel".trn


  def self.get_default_status(get_id=false)
    setup = EsSetup.get_setup('ressource_init_statut',nil)
    tmp_setup = self.find_by_code(setup)
    return tmp_setup ? (get_id ? tmp_setup.id : setup) : nil
  end

  def get_code_text
    text = self.code 
    text += " - #{self.description}" unless self.description.blank?
  end

  def next
    elem = self.class.where(["sequence > ?",self.sequence]).order("sequence asc")
    return elem.first
  end

  def previous
    elem = self.class.where(["sequence < ?",self.sequence]).order("sequence desc")
    return elem.first
  end


end
