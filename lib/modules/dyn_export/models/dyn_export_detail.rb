# encoding: UTF-8
class DynExportDetail < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to :dyn_export

  acts_as_audited :keep_text          => true,
                  :child_attrs => { :dyn_export => :name},
                  :model_audit_label  => "Dynamic Export detail".trn,
                  :process_label      => "Manual change".trn

  attr_accessible :clause, :sequence, :name, :operator, :argument, :active, :params, :dyn_export_id


  def get_audit_label
    "#{self.dyn_export.code} #{self.clause} #{self.sequence}" 
  end

  def compress_sequence(condition={})
    self.dyn_export.compress_sequence(condition)
  end   
     
end
