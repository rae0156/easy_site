# encoding: UTF-8 

class DirBase < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  stampable
  has_many     :dir_managers 

  attr_accessible :name, :description, :local_path

  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Répertoires de base".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

private

end