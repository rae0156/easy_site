# encoding: UTF-8

class EsMenu < ActiveRecord::Base

  belongs_to :es_site
  belongs_to :es_category  
  has_and_belongs_to_many :es_roles

  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name, :es_site => :code  },
                  :model_audit_label  => "Menu".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end
    
  def self.get_code_menu_sidebar
    EsMenu.where(:link_type => 'side', :parent_id => 0).all.map{|element| element.name}.uniq
  end

  def self.get_code_menu_navigation
    EsMenu.where(:link_type => 'navigation', :parent_id => 0).all.map{|element| element.name}.uniq
  end

  def self.get_code_menu_dropdown
    EsMenu.where(:link_type => 'dropdown', :parent_id => 0).all.map{|element| element.name}.uniq
  end

  def self.get_code_menu_vertical
    EsMenu.where(:link_type => 'vertical_menu', :parent_id => 0).all.map{|element| element.name}.uniq
  end

  def self.get_code_menu_sheet
    EsMenu.where(:link_type => 'sheet', :parent_id => 0).all.map{|element| element.name}.uniq
  end

  def self.get_code_menu_horizontal
    EsMenu.where(:link_type => 'horizontal', :parent_id => 0).all.map{|element| element.name}.uniq
  end
    
end