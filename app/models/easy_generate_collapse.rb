# encoding: UTF-8

class EasyGenerateCollapse < ActiveRecord::Base
  self.table_name = "es_media_files"

  belongs_to :es_category
  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Type dépliable".trn,
                  :process_label      => "Changement manuel".trn

end