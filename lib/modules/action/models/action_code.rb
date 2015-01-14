# encoding: UTF-8 

class ActionCode < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Code action".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.code
  end

end