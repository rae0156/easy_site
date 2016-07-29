# encoding: UTF-8

class EsAbility < ActiveRecord::Base

  has_and_belongs_to_many :es_roles    
  acts_as_dynamic_model([{:name => "model",
                          :type => "list_free",
                          :field_key => true,
                          :field_key_scope => "action",
                          :mandatory => true},
                         {:name => "action",
                          :type => "list_free",
                          :mandatory => true,
                          :column_name => "Liste d'actions",
                          :column_text => "manage = toutes les actions",
                          :label_name => "Liste d'actions" },
                         {:name => "description",
                          :type => "text", 
                          :link_update => true},
                         {:name => "include_not_connected",
                          :display_list => false,
                          :column_name => 'Non connectés inclus',
                          :label_name => 'Non connectés inclus' }
                      ],{:audit_model=>false})

  acts_as_audited :keep_text          => true,
                  :child_attrs => {},
                  :model_audit_label  => "Droits modèle".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.model + " " + self.action
  end

  
end