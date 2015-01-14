# encoding: UTF-8 

class ActionUser < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  belongs_to :user, :foreign_key => "user_id", :class_name => "EsUser" 
  has_many   :action_user_params 
  belongs_to :action_type 
  has_many   :action_screens 

  before_destroy :check_dependances

  attr_accessible :name, :description, :action_type_id, :user_id, :target_other, :image_name, :image_with_text
  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :action_type_id, :message => '#' + "Le type d'action est obligatoire".trn
  validates_presence_of :user_id, :message => '#' + "L'utilisateur est obligatoire".trn

  acts_as_audited :keep_text          => true,
                  :child_attrs => {:action_type => :name },
                  :model_audit_label  => "Action utilisateur".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

  
  cattr_accessor :params_from_controller
  self.params_from_controller = {} 

  def self.init_param_from_controller(param_key=nil,param_value=nil) 
    if param_key.nil? 
      self.params_from_controller = {} 
    else 
      self.params_from_controller[param_key.to_s.to_sym] = param_value 
    end 
  end 
  
  
  def user_name
    return (user.blank? || user_id==0) ? "Tous".trn : "#{user.name} #{user.firstname}"
  end

  def get_action_and_parameters

    params={}
    self.action_user_params.each do |p|
      params[p.action_type_param.name.to_sym]=p.value
    end
    self.class.params_from_controller.each do |k,v|
      params[k] = v
    end
       
    return {:type => self.action_type.caller_type, :name => self.action_type.caller_name, :action => self.action_type.caller_action},params
  end

  def save_params(params)
    list_params = []
    params.each do |p,v|
      list_params << p.to_s
      type_param = self.action_type.action_type_params.find_by_name(p.to_s)
      next if type_param.blank?
      param = self.action_user_params.find_by_action_type_param_id(type_param.id)
      if param.blank?
        ActionUserParam.create({:action_user_id => self.id, :action_type_param_id => type_param.id, :value => v})
      else
        param.update_attribute('value',v)
      end      
    end unless params.blank?
    self.action_user_params.each do |p|
      p.destroy if p.action_type_param.blank? || !list_params.include?(p.action_type_param.name) 
    end
  end

  def self.must_have_params(params,params_names=[])
    miss=[]
    params_names.each do |n|
      if params[n].presence.nil?
        miss << n
      end
    end
    return miss
  end

private


  def check_dependances
    unless self.action_user_params.empty?
      #self.errors.add("base", "Impossible de supprimer ce contenu, parce qu'il est a des assigné à des paramètres".trn)
      self.action_user_params.destroy_all
    end
    unless self.action_screens.empty?
      self.action_screens.destroy_all
    end
    return (self.errors.empty?)
  end

end