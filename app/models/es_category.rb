# encoding: UTF-8

class EsCategory < ActiveRecord::Base
  self.columns.each { |c| attr_accessible c.name.to_sym}

  has_many :es_articles
  has_many :es_menus
  has_many :es_roles
  has_many :es_setups
  has_many :es_statuses
  has_many :es_templates
  has_many :es_media_files
  has_many :es_users
  acts_as_dynamic_model([],{:audit_model=>false}) 
  
  acts_as_audited :keep_text          => true,
                  :child_attrs => {},
                  :model_audit_label  => "Catégorie".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end
  
  def self.get_id(cat_name, cat_type)
    cat = self.find(:first, :conditions => ["name = ? and category_type = ?", cat_name, cat_type] )
    return cat.blank? ? 0 : cat.id
  end


  def self.get_categories(cat_type)
    tmp_cats = self.find(:all, :conditions => ["category_type = ?",  cat_type],:order => "name" )
    cats = []
    tmp_cats.each do |c|
      cats << c if c.children.empty?
    end
    return cats
  end


end