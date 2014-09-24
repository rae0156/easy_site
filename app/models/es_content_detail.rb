# encoding: UTF-8

class EsContentDetail < ActiveRecord::Base

  belongs_to :es_content
  belongs_to :es_module
  has_many :es_content_detail_params, :order => "sequence"

  acts_as_multi_site
  attr_accessible :sequence, :es_content_id, :content, :editable, :content_type, :name, :module_action_name
#  acts_as_dynamic_model 
 
  validates_presence_of :content_type, :message => '#' + 'Le type de contenu est obligatoire'.trn
  validates_uniqueness_of :es_content_id, :message => "#" + "Ce nom de contenu existe déjà".trn,:scope => :sequence
  validates_presence_of :module_action_name, :message => '#' + "Une action de module est obligatoire".trn, :if => Proc.new { |f|  f.content_type==EsContent::CONTENT_TYPES_MODULE }
    
  before_destroy :check_dependances
  
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  
  
  
  def create_module_params(module_params)
    existing_values={}
    self.es_content_detail_params.each do |p|
      existing_values[p.setup_name] = p.value
    end

    self.es_content_detail_params.destroy_all
    module_params.each_with_index do |p,i|
      tmp_attributes = p.attributes.except("path_setup","id","module_name")
      tmp_attributes["sequence"] = i 
      tmp_attributes["value"]    = existing_values[tmp_attributes["setup_name"]] if existing_values[tmp_attributes["setup_name"]].present?   
      param = EsContentDetailParam.new(tmp_attributes)
      self.es_content_detail_params << param
    end
    
    module_action_name = self.module_action_name.split(' ')
    self.content = "<%= generate_module_part(" + '"' + module_action_name[0] + '","' + module_action_name[1] + '"' + ",#{self.id})%>"
    self.save
  end

  def save_module_params(module_params)
    module_params.each do |k,v|
      self.es_content_detail_params.find_by_setup_name(k).update_attribute("value",v)
    end
  end

  
  def check_dependances
    unless self.es_content_detail_params.empty?
      #self.errors.add("base", "Impossible de supprimer ce contenu, parce qu'il est a des assigné à des paramètres".trn)
      self.es_content_detail_params.destroy_all
    end
    return (self.errors.empty?)
  end


  def name=(name)    
    self.es_content.name=name
  end

  def name
    return self.es_content.blank? ? "" : self.es_content.name
  end


  def used?
    return self.es_content.used?
  end

  def content_detail_name
    "Elément numéro %{num}".trn(:num => self.sequence.to_i) 
  end

end