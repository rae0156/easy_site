# encoding: UTF-8

class EsUser < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_and_belongs_to_many :es_roles
  belongs_to :es_category  
  

  def role?(role)
      return !!self.es_roles.find_by_name(role.to_s)
  end  
  
end