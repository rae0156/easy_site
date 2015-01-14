# encoding: UTF-8 

class PostitList < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  stampable
  belongs_to :owner, :foreign_key => "owner_id", :class_name => "EsUser" 
  belongs_to  :postit_phase 
  has_many    :postit_tasks, :order => "sequence asc" 

  attr_accessible :name, :description, :postit_phase_id, :templatable, :checkable, :sequential, :completed, :postit_task_ids, :owner_id, :close_date

  before_destroy :check_dependances

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :owner_id, :message => '#' + "Le responsable est obligatoire".trn

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:postit_phase => :name, :owner => :mail},
                  :model_audit_label  => "Liste de tâches".trn,
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

  def get_last_sequence_closed
    last=0
    self.postit_tasks.each do |t|
      last = t.sequence.to_i if t.checked=="Y" && t.optional=='N' 
    end
    return last
  end

  def get_first_sequence_opened
    first=0
    self.postit_tasks.each do |t|
      if t.checked=="N" && t.optional=='N'
        first = t.sequence.to_i
        break
      end 
    end
    return first
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
    return "COMPLETE" if self.postit_tasks.size == 0
    one_complete    =false
    one_not_complete=false
    self.postit_tasks.each do |t|
      if t.optional=='N'
        if t.checked=="Y"
          one_complete = true
        else
          one_not_complete = true
        end      
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

  def compress_task
    self.postit_tasks.each_with_index do |t,i|
      t.update_attribute("sequence",i+1)
    end
  end

private


  def check_dependances
    unless self.postit_tasks.empty?
      self.postit_tasks=[]
    end
    return (self.errors.empty?)
  end

end
                      
