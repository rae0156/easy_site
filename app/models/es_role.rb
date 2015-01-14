# encoding: UTF-8

class EsRole < ActiveRecord::Base

  has_and_belongs_to_many :es_users
  has_and_belongs_to_many :es_menus
  belongs_to :es_category    
  has_and_belongs_to_many :es_abilities
  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Rôle".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end
  
end