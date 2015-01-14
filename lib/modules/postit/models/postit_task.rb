# encoding: UTF-8 

class PostitTask < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  stampable

  belongs_to :owner, :foreign_key => "owner_id", :class_name => "EsUser" 
  belongs_to  :postit_list 
  has_and_belongs_to_many :action_users  

  attr_accessible :name, :description, :postit_list_id, :sequence, :checked, :templatable, :optional, :action_user_ids, :owner_id, :close_date

  before_destroy :check_dependances

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :owner_id, :message => '#' + "Le responsable est obligatoire".trn

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:postit_list => :name, :owner => :mail },
                  :model_audit_label  => "Tâche".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

  def close_date_text
    return self.close_date.blank? ? "/" : self.close_date.strftime("%d/%m/%Y %H:%M:%S")
  end

  def owner_name
    return (owner.blank? || owner_id==0) ? "Tous".trn : "#{owner.name} #{owner.firstname}"
  end

  def can_be_closed
    return false if self.checked == "Y" || self.postit_list.nil? || self.postit_list.checkable == "N" 
    return true if self.optional == "Y" || self.postit_list.sequential == "N"
    return true if self.sequence.to_i == self.postit_list.get_first_sequence_opened    
    return false
  end

  def can_be_opened
    return false if self.checked == "N" || self.postit_list.nil? || self.postit_list.checkable == "N" 
    return true if self.optional == "Y" || self.postit_list.sequential == "N"
    return true if self.sequence.to_i == self.postit_list.get_last_sequence_closed        
    return false
  end

  def status_name
    unless self.checked=="Y"
      text = "A faire".trn
    else
      text = "Terminée".trn
    end
    return text
  end

private


  def check_dependances
    unless self.action_users.empty?
      self.action_user_ids=nil
    end
    return (self.errors.empty?)
  end


end
                      
