# encoding: UTF-8 

class ActionUser < ActiveRecord::Base

  has_es_interface_models

  belongs_to :user, :foreign_key => "user_id", :class_name => "EsUser" 
  has_many   :action_user_params 
  belongs_to :action_type 
  has_many   :action_screens 

  before_destroy :check_dependances

  attr_accessible :name, :description, :action_type_id, :user_id
  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :action_type_id, :message => '#' + "Le type d'action est obligatoire".trn
  validates_presence_of :user_id, :message => '#' + "L'utilisateur est obligatoire".trn
  
  def user_name
    return (user.blank? || user_id==0) ? "Tous".trn : "#{user.name} #{user.firstname}"
  end

  def get_action_and_parameters
    params={}
    self.action_user_params.each do |p|
      params[p.action_type_param.name.to_sym]=p.value
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