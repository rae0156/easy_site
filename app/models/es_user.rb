# encoding: UTF-8

#include encryption method
require 'bcrypt'

class EsUser < ActiveRecord::Base

  model_stamper
  acts_as_multi_site
  
#  acts_as_dynamic_model 

  has_and_belongs_to_many :es_roles
  belongs_to :es_category  
  #has_many :es_abilities
  
  #include encryption method
  include BCrypt

  attr_accessor :password1, :password2, :oldpassword, :special_action
  attr_accessible :mail, :password, :name, :firstname, :active, :password1, :password2, :oldpassword, :password_hash, :address1, :address2, :zip, :city, :country, :tel, :gsm, :es_role_ids, :pseudo,:newmail,:activemail
  cattr_accessor :current_user

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :firstname, :message => '#' + 'Le prenom est obligatoire'.trn
  validates_presence_of :mail, :message => '#' + 'Le mail est obligatoire'.trn
  validates_uniqueness_of :mail, :case_sensitive => false, :message => "#" + "Ce mail existe déjà".trn, :scope => :es_site_id
  validates_uniqueness_of :pseudo, :case_sensitive => false, :message => "#" + "Ce pseudo existe déjà".trn, :allow_blank => true, :allow_nil => true, :scope => :es_site_id
  validates :mail, :format => { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :if => Proc.new { |user| !user.mail.blank?}, :message => "#" + "Le format du mail n'est pas valide".trn}
  validates :newmail, :format => { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :if => Proc.new { |user| !user.newmail.blank?}, :message => "#" + "Le format du nouveau mail n'est pas valide".trn}

  validate :validate_user

  before_destroy :check_dependances

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Utilisateur".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.mail
  end
  
  def check_dependances

    linked = detect_association(['audits','es_roles'])  
    unless linked.blank?
      errors.add(:base, "La suppression de l'utilisateur ne peut être faite, car une ou plusieurs liaisons existent. (%{linked})".trn(:linked => linked.join(', ')))
    end

    unless self.es_roles.empty?
      errors.add "base", "Impossible de supprimer l'utilisateur, parce qu'il est déjà associé à un rôle".trn
    end
    return (self.errors.empty?)
  end

  def complete_name
    return self.name + ' ' + self.firstname
  end

  def validate_user

      if self.newmail
        if self.newmail == self.mail
          errors.add("newmail","#" + "Le mail ne doit pas être le même que le précédent".trn)
        end    
      end
      
      unless self.pseudo.blank?
        if self.pseudo.length > 20
          errors.add("pseudo","#" + "Le pseudo ne doit pas dépasser 20 caractères".trn)
        end    
      end
      
      if self.password1
        if self.special_action == 'update'
          unless self.password1.length > 5 || self.password1.length == 0
            errors.add("password1","#" + "Le mot de passe doit contenir au moins 6 caractères".trn)
          end    
        else
          unless self.password1.length > 5
            errors.add("password1","#" + "Le mot de passe doit contenir au moins 6 caractères".trn)
          end    
        end
      end
      if self.oldpassword
        unless self.password==self.oldpassword
          errors.add("oldpassword","#" + "L'ancien mot de passe n'est pas valide".trn)
        end    
      end
      
      unless self.password1 == self.password2
        errors.add("password2","#" + "Le mot de passe n'a pas été validé correctement".trn)
      end
      if self.password1
        if self.oldpassword==self.password1
          errors.add("password1","#" + "Le nouveau mot de passe est le même que l'ancien".trn)
        end
      end    
  end


  def password
    unless password_hash.nil?
      @password ||= Password.new(password_hash)
    end
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end



  def self.authenticate(mail,tmp_password)
    
    current_user = EsUser.find_by_mail(mail)
    if current_user.blank?
      return nil
    else
      if current_user.password == tmp_password
        return current_user
      else
        return nil
      end
    end
  end

  def self.role?(role)
    if self.current_user.blank?
      return false
    else
      return self.current_user.role?(role)
    end
  end

  def role?(role)
    if role.is_a?(Array) && self.es_roles
      role.each do |r|
        return true if self.es_roles.find_by_name(r.to_s)
      end
    else
      return !!self.es_roles.find_by_name(role.to_s)
    end
    return false
  end  
    
  def detect_association(exception_models=[])
    linked=[]
    EsUser.reflect_on_all_associations.each do |elem|
      unless exception_models.include?(elem.name.to_s)
        case elem.macro.to_s
        when "has_many", "has_and_belongs_to_many"
          linked << elem.name.to_s.humanize if  self.send(elem.name).count > 0
        end
      end        
   end
   return linked
  end
  
end