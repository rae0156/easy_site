#################################
#          WorkFlow             #
#################################

class DynWorkflowType < ActiveRecord::Base 
  has_many :dyn_workflows, :class_name => "DynWorkflow", :foreign_key => "dyn_workflow_type_id"  
  attr_accessible :code, :label
  
  def self.get_id(code)
    wft = self.find_by_code(code)
    return wft.blank? ? nil : wft.id 
  end
end 


class DynWorkflow < ActiveRecord::Base 
  has_many :dyn_workflow_statuses, :foreign_key => "dyn_workflow_type_id", :class_name => "DynWorkflowType"  

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

  def self.is_4_eyes(workflow_type_id, start_status_id, end_status_id)
    w = DynWorkflow.find :first, :conditions => ["dyn_workflow_type_id = ? and start_status_id = ? and end_status_id = ?", workflow_type_id, start_status_id, end_status_id]
    w.nil? ? false : (w.check_user == 'Y')
  end
  
private

  def self.init_role(role_association, table_name, user_model_name)
    self.user_model_name = user_model_name
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

  def self.get_user_roles
    return [] if self.user_model_name.nil?
    begin
      usermodel = self.user_model_name.constantize
      if usermodel.respond_to?('current_user')
        if usermodel.current_user.respond_to?("#{self.role_enable.singularize}_ids")
          return usermodel.current_user.send("#{self.role_enable.singularize}_ids")
        end
      end
      return []
    rescue  
      puts "Warning : user model name '#{self.user_model_name}' does not exist" 
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

      if !tmp_role_model_name.blank?
        DynWorkflow.send("init_role",tmp_role_model_name.tableize,table_name,tmp_user_model_name) 
      elsif table_name=='' 
         puts("Warning : roles for Dynamic Workflow is disabled")   
      else
         puts("Warning : '#{table_name}' does not exist. Check the option ':role_model_name'")   
      end


      belongs_to :dyn_workflow_status, :foreign_key => "dyn_workflow_status_id", :class_name => "DynWorkflowStatus"  

      DynWorkflowType.set_table_name(self.table_name_workflow_type) 
      DynWorkflow.set_table_name(self.table_name_workflow) 
      DynWorkflowStatus.set_table_name(self.table_name_workflow_status) 
      
      
      include Workflow 
      
      validate :validate_workflow 

      if self.respond_to?('before_validation_on_create') 
        before_validation_on_create :init_workflow_status #rails 2
      else 
        before_validation :init_workflow_status , :on => :create #rails 3
      end 

      
  
    end 
    
    def can_have_workflow? 
      if !(ActiveRecord::Base.connection.table_exists? self.table_name_workflow_type  and ActiveRecord::Base.connection.table_exists? self.table_name_workflow and ActiveRecord::Base.connection.table_exists? self.table_name_workflow_status)
        puts("'Acts_as_Workflow' error : Tables '#{self.table_name_workflow_type}', '#{self.table_name_workflow}' and '#{self.table_name_workflow_status}' must be created")
        return false
      elsif !(self.column_names.include?('dyn_workflow_status_id') && self.column_names.include?('dyn_workflow_user_id'))
        puts("'Acts_as_Workflow' error : The fields 'dyn_workflow_status_id' and 'dyn_workflow_user_id' must exist in table '#{self.table_name}'")        
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

    def create_one_workflow(status_start,to_status,workflow_type = self.workflow_type)
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

    def get_first_status(workflow_type = self.workflow_type)
      return DynWorkflow.get_first_status(workflow_type)      
    end
  
private 


  end 
  
  module InstanceMethods 

    def get_first_status(workflow_type = self.class.workflow_type)
      return self.class.get_first_status(workflow_type)      
    end

    def get_next_statuses(user_id = nil,workflow_type = self.class.workflow_type)
      wft_id = DynWorkflowType.get_id(workflow_type)
      include_4_eyes = (user_id.blank? || self.dyn_workflow_user_id.blank? || !(self.dyn_workflow_user_id == user_id))
      return DynWorkflow.get_next_statuses(wft_id, self.dyn_workflow_status_id,include_4_eyes)
    end

    def get_next_statuses_name(user_id = nil,workflow_type = self.class.workflow_type)
      wft_id = DynWorkflowType.get_id(workflow_type)
      include_4_eyes = (user_id.blank? || self.dyn_workflow_user_id.blank? || !(self.dyn_workflow_user_id == user_id))
      return DynWorkflow.get_next_statuses_name(wft_id, self.dyn_workflow_status_id,include_4_eyes)
    end

    def is_4eyes?(next_status,workflow_type = self.class.workflow_type)
      next_status_id = DynWorkflowStatus.get_id(next_status)
      wft_id = DynWorkflowType.get_id(workflow_type)
      return (wft_id && next_status_id) ? DynWorkflow.is_4_eyes(wft_id, self.dyn_workflow_status_id, next_status_id) : false
    end
  
    def status_name
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)
      return self.dyn_workflow_status_id.blank? || st.blank? ? "[Unknown]" : st.status_name
    end

    def is_status?(status_name)
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)
      return (self.dyn_workflow_status_id.blank? || st.blank? ? "" : st.status_name) == status_name
    end

    def is_first_status?
      fst = self.get_first_status      
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)      
      return (self.dyn_workflow_status_id.blank? || st.blank? || fst.blank? ? false : fst.status_name == st.status_name)
    end

    def is_last_status?
      st = DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id||0)      
      return (self.dyn_workflow_status_id.blank? || st.blank? ? false : DynWorkflow.get_last_statuses_name(self.workflow_type).include?(st.status_name))
    end
  
  
private 
    def init_workflow_status
      wfs = self.get_first_status
      self.dyn_workflow_status_id = wfs.id unless wfs.blank?
    end

    def validate_workflow
      if self.dyn_workflow_status_id.nil?
        errors.add_to_base("Workflow status is mandatory") 
      elsif DynWorkflowStatus.find_by_id(self.dyn_workflow_status_id).nil?
        errors.add_to_base("Workflow status does not exist") 
      else
        if !self.dyn_workflow_status_id_change.nil? 
          st_lst = DynWorkflow.get_next_statuses_name(DynWorkflowType.get_id(workflow_type), self.dyn_workflow_status_id_change[0],true)           
          errors.add_to_base("The next status '#{self.status_name}' is not a valid status (#{st_lst.join(",")})") if !st_lst.include?(self.status_name)
        end        
        
        if self.class.workflow_by_user
          errors.add_to_base("Workflow user is mandatory") if self.dyn_workflow_user_id.nil?
          if self.dyn_workflow_user_id_change.nil? && !self.dyn_workflow_status_id_change.nil? && DynWorkflow.is_4_eyes(DynWorkflowType.get_id(self.workflow_type) ,self.dyn_workflow_status_id_change[0],self.dyn_workflow_status_id)
            errors.add_to_base("4 eyes error : the next status '#{self.status_name}' must be assigned by another user than you") 
          end        
        end
      end      
    end

  end  
  
end 
