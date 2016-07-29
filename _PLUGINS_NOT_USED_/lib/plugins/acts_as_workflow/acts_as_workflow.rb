# encoding: UTF-8
#################################
#          WorkFlow             #
#################################

class DynWorkflowType < ActiveRecord::Base 

  has_many :dyn_workflows, :class_name => "DynWorkflow", :foreign_key => "dyn_workflow_type_id"  
  attr_accessible :code, :label
  
  
  def dyn_workflow_statuses
    statuses = []
    ids = []
    self.dyn_workflows.each do |w|
      unless ids.include?(w.start_status_id)
        ids       << w.start_status_id
        statuses  << w.start_status
      end
      unless ids.include?(w.end_status_id)
        ids       << w.end_status_id 
        statuses  << w.end_status
      end
    end 
    return statuses
  end
  
  def self.get_id(code)
    wft = self.find_by_code(code)
    return wft.blank? ? nil : wft.id 
  end
end 


class DynWorkflow < ActiveRecord::Base 

  belongs_to :dyn_workflow_type, :foreign_key => "dyn_workflow_type_id", :class_name => "DynWorkflowType"  

  belongs_to :start_status, :class_name => "DynWorkflowStatus", :foreign_key => "start_status_id"
  belongs_to :end_status, :class_name => "DynWorkflowStatus", :foreign_key => "end_status_id"
  
  attr_accessible :start_status_id, :end_status_id, :check_user, :dyn_workflow_type_id, :comments
  cattr_accessor :role_enable
  cattr_accessor :user_model_name
  
  
  
  def self.get_first_status(workflow_type_code)
    wft_id = DynWorkflowType.get_id(workflow_type_code)
    wfs = []
    DynWorkflow.find(:all, :conditions => {:dyn_workflow_type_id => wft_id}).each do |wf|
      wfs << wf if !wf.start_status.blank? && DynWorkflow.find(:all, :conditions => {:dyn_workflow_type_id => wft_id,:end_status_id => wf.start_status_id}).blank?
    end
    wfs = workflow_by_role(wfs, get_user_roles)

    return wfs.blank? ? nil : wfs.first.start_status
  end

  def self.get_last_statuses(workflow_type_code)
    wft_id = DynWorkflowType.get_id(workflow_type_code)
    wfs = []
    DynWorkflow.find(:all, :conditions => {:dyn_workflow_type_id => wft_id}).each do |wf| 
      wfs << wf if !wf.end_status.blank? && DynWorkflow.find(:all, :conditions => {:dyn_workflow_type_id => wft_id,:start_status_id => wf.end_status_id}).blank?
    end
    statuses = workflow_by_role(wfs, get_user_roles).collect{|wf| wf.end_status}
    
    return statuses.uniq
  end

  def self.get_last_statuses_name(workflow_type_code)
    self.get_last_statuses(workflow_type_code).collect {|ws| ws.status_name}
  end
  
  def self.get_next_statuses(workflow_type_id,start_status_id,include_4_eyes=true)
    if include_4_eyes
      ws = DynWorkflow.all(:conditions => ["dyn_workflow_type_id = ? and start_status_id = ?", workflow_type_id, start_status_id], :include => [:start_status, :end_status], :order => "end_statuses_#{self.table_name}.status_name")
    else
      ws = DynWorkflow.all(:conditions => ["dyn_workflow_type_id = ? and start_status_id = ? and check_user <> 'Y'", workflow_type_id, start_status_id], :include => [:start_status, :end_status], :order => "end_statuses_#{self.table_name}.status_name")
    end
    ws = workflow_by_role(ws,get_user_roles)

    ws.collect {|w| w.end_status}
  end

  def self.get_next_statuses_name(workflow_type_id,start_status_id,include_4_eyes=true)
    self.get_next_statuses(workflow_type_id,start_status_id,include_4_eyes).collect {|ws| ws.status_name}
  end

  def self.get_next_statuses_label(workflow_type_id,start_status_id,include_4_eyes=true)
    self.get_next_statuses(workflow_type_id,start_status_id,include_4_eyes).collect {|ws| ws.label}
  end

  def self.is_4_eyes(workflow_type_id, start_status_id, end_status_id)
    w = DynWorkflow.find :first, :conditions => ["dyn_workflow_type_id = ? and start_status_id = ? and end_status_id = ?", workflow_type_id, start_status_id, end_status_id]
    w.nil? ? false : (w.check_user == 'Y')
  end
  
  
  
  def self.create_workflow(workflows={},workflow_type)
    workflows.each do |k,v|

      status_start = k.to_s.downcase
      if v.is_a?(Array)  
        v.each do |vone|
          create_one_workflow(status_start,vone,workflow_type)
        end
      else
        create_one_workflow(status_start,v,workflow_type)
      end
    
    end
  
  end

  def self.create_one_workflow(status_start,to_status,workflow_type = workflow_type)
    workflowtype = (DynWorkflowType.find_by_code(workflow_type) || DynWorkflowType.create({:code => workflow_type, :label => workflow_type})) 
    if to_status.is_a?(Hash)          
      status_end   = (to_status[:status_end] || 'closed').to_s.downcase
      check_user   = (to_status[:check_user] || 'N')=='Y' ? 'Y' : 'N'
    else
      status_end   = to_status.to_s.downcase
      check_user = 'N'
    end
    
    sts = (DynWorkflowStatus.find_by_status_name(status_start) || DynWorkflowStatus.create({:status_name => status_start, :label => status_start}))      
    ste = (DynWorkflowStatus.find_by_status_name(status_end)   || DynWorkflowStatus.create({:status_name => status_end, :label => status_end}))      
    
    wf = DynWorkflow.find(:first, :conditions => ["dyn_workflow_type_id = ? AND start_status_id = ? and end_status_id = ?",workflowtype.id,sts.id,ste.id])
    if wf
      wf.update_attributes({:check_user => check_user,:comments=>"#{status_start} => #{status_end}"})
    else
      DynWorkflow.create({:dyn_workflow_type_id => workflowtype.id, :start_status_id => sts.id, :end_status_id => ste.id,:check_user => check_user, :comments=>"#{status_start} => #{status_end}"})
    end
  end
  
  
  
  
private

  def self.init_user(user_model_name)
    self.user_model_name = user_model_name
  end  

  def self.init_role(role_association, table_name)
    self.role_enable = role_association
    has_and_belongs_to_many role_association.to_sym, :join_table => table_name
  end  

  def self.workflow_by_role(workflows,user_role_ids)
    if self.role_enable.nil? || user_role_ids.nil?
      return workflows
    elsif workflows.is_a?(Array)
      ws_final = []
      workflows.select! do |w|
        ws_final << w if self.is_role?(w,user_role_ids)
      end
      return ws_final
    else
      return self.is_role?(w,user_role_ids) ? workflows : nil
    end
  end

  def self.is_role?(wf,user_role_ids)
    wf.send(self.role_enable).each do |r|
      return true if user_role_ids.include?(r.id)
    end    
    return false
  end

  def self.current_user_id
    return nil if self.user_model_name.nil?
    begin
      usermodel = self.user_model_name.constantize
      if usermodel.respond_to?('current_user')
        return usermodel.current_user.id
      end
      return nil
    rescue  
      return nil   
    end
  end

  def self.get_user_roles
    return [] if self.user_model_name.nil? || self.role_enable.nil? 
    begin
      usermodel = self.user_model_name.constantize
      if usermodel.respond_to?('current_user')
        if usermodel.current_user.respond_to?("#{self.role_enable.singularize}_ids")
          return usermodel.current_user.send("#{self.role_enable.singularize}_ids")
        end
      end
      return []
    rescue  
      puts "Attention : le nom du modèle user '#{self.user_model_name}' n'existe pas" 
      return []    
    end
  end

end



class DynWorkflowStatus < ActiveRecord::Base 

  belongs_to :dyn_workflow, :foreign_key => "dyn_workflow_id", :class_name => "DynWorkflow" 
  attr_accessible :status_name, :label
 
  def self.get_id(status_name)
    wfs = self.find_by_status_name(status_name)
    return wfs.blank? ? nil : wfs.id 
  end
 
end 
 

module ActsAsworkflow
  module AddActAsMethods
    
    
    def self.included(base)
       base.extend(AddActAsMethods)
    end
  
 
    def has_workflow(options = {}) 
      
      
      cattr_accessor :table_name_workflow_type 
      cattr_accessor :table_name_workflow 
      cattr_accessor :table_name_workflow_status 
      self.table_name_workflow_type   = options[:table_name_workflow_type]   || 'workflow_types' 
      self.table_name_workflow        = options[:table_name_workflow]        || 'workflows' 
      self.table_name_workflow_status = options[:table_name_workflow_status] || 'workflow_statuses' 
      return unless can_have_workflow? 

      attr_accessible :dyn_workflow_status_id, :dyn_workflow_user_id
      attr_accessible :dyn_workflow_type_id if self.column_names.include?('dyn_workflow_type_id')

      tmp_user_model_name = (options[:user_model_name] || "User").classify

      tmp_role_model_name = (options[:role_model_name] || "Role").classify
      if tmp_role_model_name==''
        table_name = ""
      else
        table_name = [tmp_role_model_name.tableize,self.table_name_workflow].sort.join('_')
        tmp_role_model_name = nil unless ActiveRecord::Base.connection.table_exists? table_name
      end
      
      cattr_accessor :workflow_type
      cattr_accessor :workflow_by_user

      self.workflow_type    = options[:workflow_type]    || self.name 
      self.workflow_by_user = options[:workflow_by_user] || false

      attr_accessor :force_status

      DynWorkflow.send("init_user",tmp_user_model_name) 
      if !tmp_role_model_name.blank?
        DynWorkflow.send("init_role",tmp_role_model_name.tableize,table_name) 
      elsif table_name=='' 
         puts("Attention : l'option 'roles' dur 'Dynamic Workflow' est désactivé")   
      else
         puts("Attention : la table '#{table_name}' n'existe pas. Vérifiez l'option ':role_model_name'")   
      end

      if self.workflow_by_user 
        belongs_to :dyn_workflow_user, :foreign_key => "dyn_workflow_user_id", :class_name => tmp_user_model_name 
      end 

      belongs_to :dyn_workflow_status, :foreign_key => "dyn_workflow_status_id", :class_name => "DynWorkflowStatus"  
      belongs_to  :dyn_workflow_type if self.column_names.include?('dyn_workflow_type_id')

      DynWorkflowType.set_table_name(self.table_name_workflow_type) 
      DynWorkflowType.acts_as_multi_site
      DynWorkflow.set_table_name(self.table_name_workflow) 
      DynWorkflow.acts_as_multi_site
      DynWorkflowStatus.set_table_name(self.table_name_workflow_status) 
      DynWorkflowStatus.acts_as_multi_site
      
      
      include Workflow 
      
      validate :validate_workflow 

      if self.column_names.include?('dyn_workflow_type_id')        
        if self.respond_to?('before_validation_on_create') 
          before_validation_on_create :init_workflow_status_instance #rails 2
          before_validation_on_update :init_workflow_status_instance #rails 2
        else 
          before_validation :init_workflow_status_instance #rails 3
        end 
      else
        if self.respond_to?('before_validation_on_create') 
          before_validation_on_create :init_workflow_status #rails 2
        else 
          before_validation :init_workflow_status , :on => :create #rails 3
        end 
      end


      
  
    end 
    
    def can_have_workflow? 
      if !(ActiveRecord::Base.connection.table_exists? self.table_name_workflow_type  and ActiveRecord::Base.connection.table_exists? self.table_name_workflow and ActiveRecord::Base.connection.table_exists? self.table_name_workflow_status)
        puts("'Acts_as_Workflow' erreur : Les tables '#{self.table_name_workflow_type}', '#{self.table_name_workflow}' et '#{self.table_name_workflow_status}' doivent être créées")
        return false
      elsif !(self.column_names.include?('dyn_workflow_status_id') && self.column_names.include?('dyn_workflow_user_id'))
        puts("'Acts_as_Workflow' erreur : Les champs 'dyn_workflow_status_id' et 'dyn_workflow_user_id' doivent exister dans la table '#{self.table_name}'")        
        return false
      else
        return true
      end
    end 
  
  end
 
  ActiveRecord::Base.send(:include, AddActAsMethods) 
 
end
 

module Workflow 
  def self.included(base) 
    base.send :extend , ClassMethods 
    base.send :include, InstanceMethods 
  end 
  
  module ClassMethods  

    def delete_workflow(workflows={},workflow_type = self.workflow_type)
      workflows.each do |k,v|
        status_start = k.to_s.downcase
        if v.is_a?(Array)  
          v.each do |vone|
            delete_one_workflow(status_start,vone,workflow_type)
          end
        else
          delete_one_workflow(status_start,v,workflow_type)
        end      
      end    
    end

    def delete_one_workflow(status_start,to_status,workflow_type = self.workflow_type)
      workflowtype = DynWorkflowType.find_by_code(workflow_type)
      return if workflowtype.blank?

      if to_status.is_a?(Hash)          
        status_end   = (to_status[:status_end] || 'closed').to_s.downcase
      else
        status_end   = to_status.to_s.downcase
      end
      
      sts = DynWorkflowStatus.find_by_status_name(status_start)      
      return if sts.blank?
      ste = DynWorkflowStatus.find_by_status_name(status_end)      
      return if ste.blank?
      
      wf = DynWorkflow.find(:first, :conditions => ["dyn_workflow_type_id = ? AND start_status_id = ? and end_status_id = ?",workflowtype.id,sts.id,ste.id])
      if wf
        wf.destroy
      end
    end
  
  
    def create_workflow(workflows={},workflow_type = self.workflow_type)
      DynWorkflow.create_workflow(workflows,workflow_type)
    end

    def get_first_status(workflow_type = self.workflow_type)
      return DynWorkflow.get_first_status(workflow_type)      
    end
  
private 


  end 
  
  module InstanceMethods 

    def get_first_status(workflow_type = nil)
      return self.class.get_first_status(get_workflow_type(workflow_type))      
    end

    def get_next_statuses(user_id = nil,workflow_type = nil)
      wft_id = DynWorkflowType.get_id(get_workflow_type(workflow_type))
      include_4_eyes = (user_id.blank? || self.dyn_workflow_user_id.blank? || !(self.dyn_workflow_user_id == user_id))
      return DynWorkflow.get_next_statuses(wft_id, self.dyn_workflow_status_id,include_4_eyes)
    end

    def get_next_statuses_name(user_id = nil,workflow_type = nil)
      wft_id = DynWorkflowType.get_id(get_workflow_type(workflow_type))
      include_4_eyes = (user_id.blank? || self.dyn_workflow_user_id.blank? || !(self.dyn_workflow_user_id == user_id))
      return DynWorkflow.get_next_statuses_name(wft_id, self.dyn_workflow_status_id,include_4_eyes)
    end

    def get_next_statuses_label(user_id = nil,workflow_type = nil)
      wft_id = DynWorkflowType.get_id(get_workflow_type(workflow_type))
      include_4_eyes = (user_id.blank? || self.dyn_workflow_user_id.blank? || !(self.dyn_workflow_user_id == user_id))
      return DynWorkflow.get_next_statuses_label(wft_id, self.dyn_workflow_status_id,include_4_eyes)
    end


    def is_4eyes?(next_status,workflow_type = nil)
      next_status_id = DynWorkflowStatus.get_id(next_status)
      wft_id = DynWorkflowType.get_id(get_workflow_type(workflow_type))
      return (wft_id && next_status_id) ? DynWorkflow.is_4_eyes(wft_id, self.dyn_workflow_status_id, next_status_id) : false
    end
  
    def status_name
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)
      return self.dyn_workflow_status_id.blank? || st.blank? ? "[Unknown]" : st.status_name
    end

    def status_label
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)
      return self.dyn_workflow_status_id.blank? || st.blank? ? "[Unknown]" : st.label
    end

    def is_status?(status_name)
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)
      return (self.dyn_workflow_status_id.blank? || st.blank? ? "" : st.status_name) == status_name
    end

    def is_first_status?(workflow_type = nil)
      fst = self.get_first_status(get_workflow_type(workflow_type))      
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)      
      return (self.dyn_workflow_status_id.blank? || st.blank? || fst.blank? ? false : fst.status_name == st.status_name)
    end

    def is_last_status?(workflow_type = nil)
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)      
      return (self.dyn_workflow_status_id.blank? || st.blank? ? false : DynWorkflow.get_last_statuses_name(get_workflow_type(workflow_type)).include?(st.status_name))
    end
  
  
  
  
  
private 
    def init_workflow_status_instance 
      if self.dyn_workflow_type_id && !self.dyn_workflow_type_id_change.nil?
        wf_status = self.get_first_status(self.dyn_workflow_type.code)
        if wf_status
          self.dyn_workflow_status_id = wf_status.id
          self.dyn_workflow_user_id   = DynWorkflow.current_user_id 
          self.force_status = true
        end 
      end
    end


    def init_workflow_status
      wfs = self.get_first_status(self.class.workflow_type)
      unless wfs.blank?
        self.dyn_workflow_status_id = wfs.id
        self.dyn_workflow_user_id = DynWorkflow.current_user_id 
      end 
    end

    def validate_workflow

      if self.respond_to?('dyn_workflow_type_id') && self.dyn_workflow_type_id.nil?      
        errors.add(:base,"Le type de flux est obligatoire".trn)
      end    
      
      if self.dyn_workflow_status_id.nil?
        if DynWorkflow.role_enable.nil?
          errors.add(:base,"Le statut du flux est obligatoire".trn)
        else
          errors.add(:base,"Le statut du flux est obligatoire. Vous n'avez peut être pas access".trn)
        end   
      elsif DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id).nil?
        errors.add(:base,"Le statut du flux n'existe pas".trn) 
      else
        if !self.dyn_workflow_status_id_change.nil? && !self.dyn_workflow_status_id_change[0].nil? && !(self.force_status==true)
          st_lst = DynWorkflow.get_next_statuses_label(DynWorkflowType.get_id(get_workflow_type), self.dyn_workflow_status_id_change[0],true)           
          errors.add(:base,"Le statut suivant '%{label}' n'est pas valide (%{list})".trn(:label => self.status_label, :list => st_lst.join(","))) if !st_lst.include?(self.status_label)
        end        
        
        if self.class.workflow_by_user
          errors.add(:base,"L'utilisateur du flux est obligatoire".trn) if self.dyn_workflow_user_id.nil?
          if self.dyn_workflow_user_id_change.nil? && !self.dyn_workflow_status_id_change.nil? && DynWorkflow.is_4_eyes(DynWorkflowType.get_id(self.workflow_type) ,self.dyn_workflow_status_id_change[0],self.dyn_workflow_status_id)
            errors.add(:base,"Erreur 4 yeux : Le statut suivant '%{label}' doit être assigné par un autre utilisateur que vous".trn(:label => self.status_label)) 
          end        
        end
      end   
      self.force_status = false if self.force_status==true   
    end

    def get_workflow_type(workflow_type = nil)
      if self.respond_to?('dyn_workflow_type')
        return self.dyn_workflow_type.code
      else
        return workflow_type || self.class.workflow_type 
      end
    end

  end  
  
end 
