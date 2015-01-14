# encoding: UTF-8 

class ActionUserParam < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to :action_user 
  belongs_to :action_type_param 

  attr_accessible :action_user_id, :action_type_param_id, :value

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:action_user => :name,:action_type_param => :name },
                  :model_audit_label  => "Paramètre d'action utilisateur".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    "#{self.action_user.name} #{self.action_type_param.name}"
  end

end