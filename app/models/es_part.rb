# encoding: UTF-8

class EsPart < ActiveRecord::Base
  belongs_to :es_template
  belongs_to :es_template_col
  belongs_to :es_content
  belongs_to :es_site
  
  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name, :es_content => :name, :es_site => :code},
                  :model_audit_label  => "Parties de template".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :description, :message => '#' + 'La description est obligatoire'.trn
  validates_uniqueness_of :name, :message => "#" + "Cette partie existe déjà pour ce template".trn,:scope => [:es_template_id,:es_site_id]


  def self.is_dynamic(part_name,directory="parts")
    return !File.exist?("#{Rails.root}/app/views/#{directory}/_#{part_name}.html.erb") 
  end
  
  def placed
    if self.es_template_col.blank?
      return nil
    else
      return "'%{part}' - position %{position}".trn(:part => self.es_template_col.description, :position =>self.num)
    end 
  end
  
  def content
    return !self.es_content.blank? || !self.is_dynamic
  end
  
  def is_dynamic
    return !File.exist?("#{Rails.root}/app/views/parts/_#{self.name}.html.erb") 
  end

  def is_editable
    editable = false
    self.es_content.es_content_details.each do |cd|
      return true if cd.editable=='Y'
    end
    editable
  end

  def type_of_part
    return !self.is_dynamic ? "Fichier".trn : "Dynamique".trn
  end
  
  def self.get_name_list
    name_list = []
    files_list = Dir.glob("#{Rails.root}/app/views/parts/_part_*.html.erb").map{|f| File.basename(f,".html.erb")[1..-1]}
    files_list.sort.each do |f|
      name_list << ["Fichier : %{name}".trn(:name => f[5..-1]),f]
    end
    
    EsContent.all(:order => "name").each do |c|
      name_list << ["Contenu : %{name}".trn(:name => c.name),c.name] unless files_list.include?(c.name)
    end
    
    return name_list
  end
  
end