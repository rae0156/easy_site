# encoding: UTF-8

class EsTemplateLine < ActiveRecord::Base

  has_many :es_template_cols, :order => "num"
  belongs_to :es_template
  belongs_to :parent, :class_name => "EsTemplateCol", :foreign_key => "es_col_parent_id"


  acts_as_multi_site
  attr_accessible :num, :es_template_id, :es_col_parent_id
 
  validates_presence_of :num, :message => '#' + 'Le numéro est obligatoire'.trn
  validates_uniqueness_of :num, :case_sensitive => false,:scope => [:es_template_id,:es_col_parent_id,:es_site_id], :message => "#" + "Cette ligne de template existe déjà".trn
    
  before_destroy :check_delete_line

  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_template => :name },
                  :model_audit_label  => "Ligne de template".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    "#{self.es_template.name} #{self.num.to_i}"
  end
  
  def check_delete_line
    unless self.content_empty?
      errors.add "base", "Impossible de supprimer cette ligne, car certaines parties y sont assignées".trn
    end
    
    if self.errors.empty?
      cols = self.es_template_cols
      cols.destroy_all unless cols.blank?
    end
    
    return (self.errors.empty?)
  end

  def column_detail
    return self.es_template_cols.map{|c| c.width}.join(', ')
  end
  
  def content_empty?    
    self.es_template_cols.each do |c|
      return false if c.es_parts.size > 0
    end
    return true
  end

end