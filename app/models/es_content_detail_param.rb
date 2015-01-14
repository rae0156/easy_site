# encoding: UTF-8

class EsContentDetailParam < ActiveRecord::Base

  belongs_to :es_content_detail
  acts_as_dynamic_model([],{:audit_model=>false}) 

  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Paramètre d'un détail de contenu".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.es_content_detail.es_content.name + " " + self.es_content_detail.sequence.to_s + " " + self.setup_name
  end

end