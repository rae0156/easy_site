# encoding: UTF-8 

class PostitProcess < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  has_workflow({:role_model_name => "EsRole", :user_model_name => "EsUser", :table_name_workflow_type => "es_workflow_types", :table_name_workflow => "es_workflows", :table_name_workflow_status => "es_workflow_statuses",:workflow_by_user => true, :role_model_name => ''})

  stampable
  belongs_to :owner, :foreign_key => "owner_id", :class_name => "EsUser" 
  belongs_to  :postit_phase 
  has_many    :postit_phases 

  attr_accessible :name, :description, :templatable, :completed, :dyn_workflow_status_id, :dyn_workflow_user_ids, :postit_phase_ids, :owner_id, :close_date

  before_destroy :check_dependances

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :owner_id, :message => '#' + "Le responsable est obligatoire".trn

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:postit_phase => :name, :owner => :mail },
                  :model_audit_label  => "Processus".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end



  def workflow_status_name
    self.dyn_workflow_status ? self.dyn_workflow_status.label : "Aucun".trn 
  end

  def self.workflow_type_list
    DynWorkflowType.all(:conditions => ["code LIKE ?","postit_process_%"])
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
      text = self.completed == 'N' ? "A faire".trn : "Cloturée".trn
    when "COMPLETE"
      text = self.completed == 'N' ? "Terminée".trn : "Cloturée".trn
    when "RUNNING"
      text = "En cours".trn
    end     
    return text
  end

  def status
    return "COMPLETE" if self.postit_phases.size == 0
    one_complete    =false
    one_not_complete=false
    self.postit_phases.each do |p|
      return "RUNNING" if p.status == "RUNNING"
      if p.status == "COMPLETE"
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

  def complete_for_this_status
    self.postit_phases.each do |p|
      if p.dyn_workflow_status_id == self.dyn_workflow_status_id
        p.postit_lists.each do |l|
          return false if l.completed=='N'
        end     
      end 
    end
    true
  end

  def postit_lists
    lists = []
    self.postit_phases.each do |p|
      if p.dyn_workflow_status.blank? || p.dyn_workflow_status_id == self.dyn_workflow_status_id
        p.postit_lists.each do |l|
          lists << l
        end     
      end 
    end
    lists
  end


private


  def check_dependances
    unless self.postit_phases.empty?
      self.postit_phases=[]
    end
    return (self.errors.empty?)
  end
end
                      


