# encoding: UTF-8

class DynPage < ActiveRecord::Base
  self.table_name = "es_dyn_pages"

  has_es_interface_models
  #acts_as_multi_site

  belongs_to :es_template

  acts_as_dynamic_model([{:name => "name",
                          :field_key => true,
                          :mandatory => true,
                          :column_name => "Nom",
                          :label_name => "Nom" },
                         {:name => "description",
                          :mandatory => false,
                          :column_name => "Description",
                          :label_name => "Description"},
                         {:name => "page_type",
                          :value_list => "page,part",
                          :mandatory => true,
                          :column_name => "Type de page",
                          :label_name => "Type de page"},
                         {:name => "es_template_id",
                          :type => "list",
                          :mandatory => false,
                          :value_list_method => "template_list",
                          :model_linked_field => 'name',
                          :column_name => "Template",
                          :label_name => "Template"}
                      ],{:audit_model=>false})
  acts_as_audited :keep_text          => true,
                  :model_audit_label  => "Page dynamique".trn,
                  :process_label      => "Changement manuel".trn
 

  def get_audit_label
    self.name
  end

  def template_list
    EsTemplate.find(:all,:conditions => {:is_a_template => 'N'}).map{|e|[e.name,e.id]}
  end

  #attr_accessible :name, :description, :page_type
 
#  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
#  validates_uniqueness_of :name, :case_sensitive => true,:scope => [:es_site_id], :message => "#" + "Ce nom de page dynamique existe déjà".trn
    
  before_destroy :check_delete_template
  before_save :create_template
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    "#{self.name}"
  end
  
  def create_template
    if !self.es_template && self.new_record?
      template = EsTemplate.create({:name => "tmp_dyn_page",:description =>  "Création du modèle pour la page dynamique %{name}".trn(:name=> self.name), :validated => "Y", :is_a_template => 'N', :es_category_id => 0})
      template.update_attribute('name',"dyn_page_#{template.id}")
      self.es_template_id = template.id
    end
  end

  def check_delete_template
    unless self.es_template.blank?
      errors.add "base", "Impossible de supprimer cette page dynamique, car un modèle est associé".trn
    end
    return (self.errors.empty?)
  end

  def self.get_menu_list
    menus = []
    self.where(:page_type => 'page').order('name').all.each do |m|
      menus << [m.description, {:controller => 'dyn_pages', :action => 'page' , :name => m.name},m.name]
    end
    return menus 
  end

  def self.get_part_name
    DynPage.where(:page_type => 'part').all.map(&:name).uniq
  end

end