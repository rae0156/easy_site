# encoding: UTF-8

class EsContentDetailElement < ActiveRecord::Base
  belongs_to :es_content_detail
  belongs_to :es_content_detail_child, :foreign_key => "es_content_detail_child_id", :class_name => "EsContentDetail" 
  
  acts_as_multi_site
  attr_accessible :name, :description, :element_type, :es_content_detail_id, :parent_id, :num

  validates_presence_of :name, :message => '#' + 'Le nom de la partie est obligatoire'.trn
  validates_uniqueness_of :name, :message => "#" + "Ce nom de partie existe déjà".trn,:scope => [:es_content_detail_id,:es_site_id]
  validates_presence_of :description, :message => '#' + "La description est obligatoire".trn

  before_destroy :check_dependances

  def check_dependances
    unless self.es_content_detail_child_id.nil?
      self.es_content_detail_child.destroy
    end
    return (self.errors.empty?)
  end


  def self.get_properties(element_type, element_id,init_properties)
    element_type.constantize # doit être là pour charger le model
    EsContent.get_properties(element_type, element_id,init_properties)
  rescue
    return [] 
  end

  
end