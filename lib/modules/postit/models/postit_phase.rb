# encoding: UTF-8 

class PostitPhase < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  stampable
  belongs_to :owner, :foreign_key => "owner_id", :class_name => "EsUser" 
  belongs_to  :postit_process 
  belongs_to  :dyn_workflow_status
  has_many    :postit_lists 

  attr_accessible :name, :description, :postit_process_id, :templatable, :postit_list_ids, :owner_id, :close_date, :dyn_workflow_status_id


  before_destroy :check_dependances

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :owner_id, :message => '#' + "Le responsable est obligatoire".trn


  acts_as_audited :keep_text          => true,
                  :child_attrs => {:postit_process => :name, :owner => :mail, :dyn_workflow_status => :status_name },
                  :model_audit_label  => "Phase de processus".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

  def workflow_status_name
    self.dyn_workflow_status ? self.dyn_workflow_status.label : "Aucun".trn 
  end

  def close_date_text
    return self.close_date.blank? ? "/" : self.close_date.strftime("%d/%m/%Y %H:%M:%S")
  end

  def owner_name
    return (owner.blank? || owner_id==0) ? "Tous".trn : "#{owner.name} #{owner.firstname}"
  end


  def status_name
    text = ""
    case self.status
    when "NONE"
      text = "A faire".trn 
    when "COMPLETE"
      text = "Terminée".trn 
    when "RUNNING"
      text = "En cours".trn
    end     
    return text
  end

  def status
    #return "COMPLETE" if self.postit_lists.size == 0
    one_complete    =false
    one_not_complete=false
    self.postit_lists.each do |l|
      return "RUNNING" if l.status == "RUNNING"
      if l.completed=="Y"
        one_complete = true
      else
        one_not_complete = true
      end      
      break if one_complete && one_not_complete
    end

    if !one_not_complete && !one_complete
      return "NONE"
    elsif one_not_complete && !one_complete
      return "NONE"
    elsif !one_not_complete && one_complete
      return "COMPLETE"
    else
      return "RUNNING"
    end
            
  end


private


  def check_dependances
    unless self.postit_lists.empty?
      self.postit_lists=[]
    end
    return (self.errors.empty?)
  end

end
                      
