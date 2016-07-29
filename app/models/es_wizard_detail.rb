# encoding: UTF-8

class EsWizardDetail < ActiveRecord::Base
  belongs_to :es_wizard

  attr_accessible :name, :sequence, :description, :controller, :action, :render_name, :params, :es_wizard_id

  acts_as_multi_site
  
  
  def previous
    return EsWizardDetail.find(:first,:conditions => ["es_wizard_id = ? and sequence < ?", self.es_wizard_id, self.sequence], :order => "sequence desc")
  end

  def next
    return EsWizardDetail.find(:first,:conditions => ["es_wizard_id = ? and sequence > ?", self.es_wizard_id, self.sequence], :order => "sequence asc")
  end
  
end