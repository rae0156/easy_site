# encoding: UTF-8 

class ActionScreen < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to :action_user 
  belongs_to :user, :foreign_key => "user_id", :class_name => "EsUser" 

  attr_accessible :action_user_id, :user_id, :x, :y

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:action_user => :name  },
                  :model_audit_label  => "Action écran".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.action_user.name
  end

end