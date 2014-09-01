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
    

end