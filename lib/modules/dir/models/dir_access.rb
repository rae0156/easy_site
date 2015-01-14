# encoding: UTF-8 

class DirAccess < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  stampable
  belongs_to   :dir_manager 
  has_and_belongs_to_many :es_roles

  attr_accessible :name, :description, :dir_manager_id, :all_role, :dir_view, :file_view, :dir_update, :file_update, :dir_del, :file_del, :dir_create, :file_create, :dir_rename, :file_rename, :file_download, :file_upload, :es_role_ids

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_uniqueness_of :name, :message => "#" + "Ce nom existe déjà".trn,:scope => :dir_manager_id

  before_save :assign_role

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:dir_manager => :name },
                  :model_audit_label  => "Droits sur répertoire".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    "#{self.dir_manager.name} #{self.name}"
  end

private

  def assign_role
    self.all_role= self.es_roles.size==0 ? 'Y' : 'N'
  end

end