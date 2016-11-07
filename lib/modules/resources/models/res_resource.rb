# encoding: UTF-8
load Rails.root + 'app/models/es_user.rb'
class EsUser < ActiveRecord::Base
  has_many :res_resources
  has_many :res_actions
  has_many :res_evals
  has_many :res_stocks
  
end

class ResResource < ActiveRecord::Base
  has_es_interface_models
  acts_as_multi_site
  
  belongs_to :res_category
  belongs_to :es_user
  belongs_to :res_status
  belongs_to :res_priority
  belongs_to :res_action
  belongs_to :res_product
  belongs_to :res_when_start, :class_name => "ResWhen", :foreign_key => "res_when_start_id"
  belongs_to :res_when_end, :class_name => "ResWhen", :foreign_key => "res_when_end_id"


  attr_accessible :name,:description,:res_category_id,:sequence,:stockable,:quantity,:qty_not_used,:es_user_id,:start_date,:end_date,:res_action_id,:res_status_id,:res_priority_id,:res_product_id,:res_when_start_id,:res_when_end_id, :comment_text, :comment_user_date

  validates_presence_of :res_product_id, :message => '#' + "Le produit est obligatoire".trn
  validates_presence_of :res_priority_id, :message => '#' + "La priorité est obligatoire".trn
  validates_presence_of :res_status_id,   :message => '#' + "Le statut est obligatoire".trn
  validates_presence_of :quantity,        :message => '#' + "La quantité est obligatoire".trn
  validates_numericality_of :quantity,    :message => '#' + "La quantité doit être numérique et supérieure à zéro".trn, :allow_nil => true, :greater_than => 0
  validates_presence_of :es_user_id,      :message => '#' + "La personne assignée est obligatoire".trn
  validates_presence_of :res_action_id,   :message => '#' + "L'action est obligatoire".trn
  #validates_presence_of :start_date,      :message => '#' + "La date 'Quand' est obligatoire".trn
  #validates_presence_of :end_date,        :message => '#' + "La date 'Pour quand' est obligatoire".trn
  validates_numericality_of :qty_not_used,    :message => '#' + "La quantité restante doit être numérique et supérieure à zéro".trn, :allow_nil => true
  
  validate :valid_resource
  
  before_validation :init_dates
  after_initialize :init_default
  
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Ressource".trn,
                  :process_label      => "Changement manuel".trn
  

  def next(user)
    elem = self.class.where(["res_category_id = ? AND sequence > ?",self.res_category_id,self.sequence]).order("sequence asc")
    elem = elem.where(:es_user_id => user) unless (user||0).to_i==0
    return elem.first
  end

  def previous(user)
    elem = self.class.where(["res_category_id = ? AND sequence < ?",self.res_category_id,self.sequence]).order("sequence desc")
    elem = elem.where(:es_user_id => user) unless (user||0).to_i==0
    return elem.first
  end
  
  def last
    elem = self.class.where(["res_category_id = ?",self.res_category_id]).order("sequence desc")
    return elem.first
  end
  
  def compress_sequence
    self.class.where(["res_category_id = ?",self.res_category_id]).order("sequence asc").each_with_index do |element,i|
      element.update_attribute("sequence",i + 1)
    end
  end

  def get_description
    return self.res_product_id ? (self.res_product.name + " " + self.description) : self.description
  end
  
  def quantity_used
    return (self.quantity||0) - (self.qty_not_used||0)
  end

  def quantity_left
    return (self.qty_not_used||0)
  end

  def information 
    
    attr=[]
    attr << "conso".trn unless (self.stockable||'N') == 'N'
    #attr << "gestion de stock".trn unless self.res_product_id.blank?
    
    #text = "#{self.quantity}"
    #unless attr.empty?
    #  text +=" (#{attr.join(' - ')})"
    #end
    #return text
    
    return attr.join(' - ')

  end

  def get_start_date
    if !self.res_when_start_id.blank? 
      self.res_when_start.name
    elsif !self.start_date.blank?
      self.start_date.strftime("%d/%m/%Y")
    else
      ''
    end
  end

  def get_end_date
    if !self.res_when_end_id.blank? 
      self.res_when_end.name
    elsif !self.end_date.blank?
      self.end_date.strftime("%d/%m/%Y")
    else
      ''
    end
  end

  def self.get_message_lock
    return EsSetup.get_setup('ressource_message_lock',nil)
  end

  def self.set_message_lock(message=nil)
    message = "Les ressources ont été bloquées par '%{user}'".trn(:user => (EsUser.current_user ? EsUser.current_user.complete_name : "Un utilisateur non connecté".trn)) if message.nil? 
    EsSetup.set_setup('ressource_message_lock',message)
  end


private
  def init_dates
    if !self.start_date.blank? && !self.res_when_start_id.blank?
      self.start_date=nil
    end
    if !self.end_date.blank? && !self.res_when_end_id.blank?
      self.end_date=nil
    end

    if !self.res_when_start_id.blank? && (self.end_date.blank? && self.res_when_end_id.blank?)
      self.res_when_end_id=self.res_when_start_id
    end
  end

  def valid_resource
    errors.add(:description,"#La description sans le produit n'est pas autorisé.".trn) if !(self.description.blank?) && self.res_product_id.blank?
    errors.add(:base,"La quantité restante '%{qty_not_used}' doit être inférieure ou égale à la quantité nécessaire '%{qty}'.".trn(:qty_not_used => self.qty_not_used, :qty => self.quantity)) if (self.qty_not_used||0) > (self.quantity||0)
    errors.add(:start_date,"#La date 'Quand' est obligatoire s'il ny a pas de moment renseigné.".trn) if self.start_date.blank? && self.res_when_start_id.blank?
    errors.add(:end_date,"#La date 'Pour quand' est obligatoire s'il ny a pas de moment renseigné.".trn) if self.end_date.blank? && self.res_when_end_id.blank?
    errors.add(:stockable,"#Vous devez choisir un produit si l'option comsommable est sélectionnée.".trn) if self.stockable=='Y' && self.res_product_id.blank?
  end

  def init_default
    return unless self.new_record?
    
    setup = EsSetup.get_setup('ressource_init_statut',nil)
    tmp_element = ResStatus.find_by_code(setup)
    self.res_status_id = tmp_element.id if tmp_element

    setup = EsSetup.get_setup('ressource_init_priorite_ressource',nil)
    tmp_element = ResPriority.find_by_code(setup)
    self.res_priority_id = tmp_element.id if tmp_element

    setup = EsSetup.get_setup('ressource_init_quand_ressource',nil)
    tmp_element = ResWhen.find_by_name(setup)
    self.res_when_start_id = tmp_element.id if tmp_element

    setup = EsSetup.get_setup('ressource_init_pour_quand_ressource',nil)
    tmp_element = ResWhen.find_by_name(setup)
    self.res_when_end_id = tmp_element.id if tmp_element

    self.es_user_id = self.res_category.responsible_a_id if self.res_category && self.res_category.responsible_a

    self.quantity = 1
  end

end
