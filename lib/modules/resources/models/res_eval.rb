# encoding: UTF-8
class ResEval < ActiveRecord::Base
  has_es_interface_models
  acts_as_multi_site

  belongs_to :res_category
  belongs_to :es_user
  
  attr_accessible :description,:res_category_id,:sequence,:es_user_id,:datetime,:year

  validates_presence_of :year, :message => '#' + "L'année est obligatoire".trn
  validates_presence_of :description, :message => '#' + "La description est obligatoire".trn

  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Evaluation".trn,
                  :process_label      => "Changement manuel".trn

  def next
    elem = self.class.where(["res_category_id = ? AND sequence > ? AND year = ?",self.res_category_id,self.sequence,self.year]).order("sequence asc")
    return elem.first
  end

  def previous
    elem = self.class.where(["res_category_id = ? AND sequence < ? AND year = ?",self.res_category_id,self.sequence,self.year]).order("sequence desc")
    return elem.first
  end

  def last
    elem = self.class.where(["res_category_id = ? AND year = ?",self.res_category_id,self.year]).order("sequence desc")
    return elem.first
  end
  
  def compress_sequence
    self.class.where(["res_category_id = ? AND year = ?",self.res_category_id,self.year]).order("sequence asc").each_with_index do |element,i|
      element.update_attribute("sequence",i + 1)
    end
  end

end
