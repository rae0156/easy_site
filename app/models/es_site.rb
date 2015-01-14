# encoding: UTF-8

class EsSite < ActiveRecord::Base
  cattr_accessor  :current_site_id

  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {},
                  :model_audit_label  => "Site".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.code
  end
  
  
  def complete_name
    "#{self.code} - #{self.description}"
  end
  
end