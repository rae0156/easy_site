# encoding: UTF-8

class EsTemplateCol < ActiveRecord::Base

  belongs_to :es_template_line
  has_many :es_parts, :order => "num"
  has_many :children, :class_name => "EsTemplateLine", :foreign_key => "es_col_parent_id"

  acts_as_multi_site
  attr_accessible :num,:width, :es_template_line_id,:description
 
  validates_presence_of :num, :message => '#' + 'Le numéro de colonne est obligatoire'.trn
  validates_presence_of :width, :message => '#' + 'La largeur de la colonne est obligatoire'.trn
  validates_uniqueness_of :num, :case_sensitive => false,:scope => [:es_template_line_id,:es_site_id], :message => "#" + "Cette colonne ligne de de template existe déjà".trn
    
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_template_line => :num },
                  :model_audit_label  => "Colonne de template".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    if self.es_template_line && self.es_template_line.es_template
      "#{self.es_template_line.es_template.name} #{self.es_template_line.num.to_i} #{self.num}"
    else
      "[template] [template_line] #{self.num}"
    end
  end

end