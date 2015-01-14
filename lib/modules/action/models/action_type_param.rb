# encoding: UTF-8 

class ActionTypeParam < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to   :action_type 

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:action_type => :name },
                  :model_audit_label  => "Paramètre de type d'actions".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    "#{self.action_type.name} #{self.name}"
  end

private

end