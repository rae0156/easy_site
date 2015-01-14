# encoding: UTF-8 

class ActionType < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  has_many   :action_users 
  has_many   :action_type_params 

  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Type d'actions".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

private

end