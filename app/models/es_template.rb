# encoding: UTF-8


class EsTemplate < ActiveRecord::Base

  has_many :es_pages
  has_many :es_parts
  has_many :es_template_lines, :order => "num"
  belongs_to :es_category

  acts_as_multi_site
  attr_accessible :name, :es_category_id, :description,:template_type, :validated, :es_template_line_ids
#  acts_as_dynamic_model 
 
  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :description, :message => '#' + 'La description est obligatoire'.trn
#  validates_presence_of :es_category_id, :message => '#' + 'La catégorie est obligatoire'.trn
  validates_presence_of :template_type, :message => '#' + 'Le type est obligatoire'.trn
  validates_uniqueness_of :name, :message => "#" + "Ce template existe déjà".trn,:scope => :es_site_id
    
  before_destroy :check_dependances



#  acts_as_dynamic_model([],{:audit_model=>false})

  acts_as_audited :keep_text          => true,
                  :child_attrs => { :es_category => :name},
                  :model_audit_label  => "Template".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

  
  def self.is_dynamic(template_name)
    return self.find_by_name(template_name).is_dynamic
  end
  
  def self.change_musique(new_musique)
    setup = EsSetup.find_by_name('musique_site')
    if setup
      setup.update_attribute('value',new_musique)
      musique = EsSetup.get_setup("musique_site","")
      Rails.application.config.current_musique = musique.blank? ? "" : (EsSetup.get_setup("répertoire_musique","public/") + musique)
    end
  end
  
  def self.change_template(new_template)
    template_from = EsTemplate.find_by_name(Rails.application.config.current_template)
    template_to = EsTemplate.find_by_name(new_template)
    EsPage.where(:es_template_id => template_from.id).each do |page|
      page.update_attribute(:es_template_id,template_to.id)
    end
    EsPage.all.each do |page|
      page.update_attribute(:es_template_id,template_to.id) if page.es_template.blank?
    end
    Rails.application.config.current_template = template_to.name
  end
  
  def is_dynamic
    return !File.exist?("#{Rails.root}/app/views/templates/_#{self.name.downcase}.html.erb")
  end
  
  def self.template_type_txt(type_of_template)
    return (case type_of_template
                when "TEMPLATE"
                  "Template"
                when "PAGE"
                  "Page"
                when "PAGE_MODEL"
                  "Modèle de page"
                else
                  list_item.template_type
                end).trn
  end
  
  def check_dependances
    unless self.es_template_lines.empty?
      self.errors.add("base", "Impossible de supprimer le template, parce qu'il est assigné à une ou plusieurs lignes de dessin".trn)
    end
    unless self.es_pages.empty?
      self.errors.add("base", "Impossible de supprimer le template, parce qu'il est assigné à une ou plusieurs actions".trn)
    end
    unless self.es_parts.empty?
      self.errors.add("base", "Impossible de supprimer le template, parce qu'il contient une ou plusieurs parties".trn)
    end
    return (self.errors.empty?)
  end


  def compress_line
    self.es_template_lines.each_with_index do |l,i|
      l.update_attribute("num",i+1)
    end
  end 

  def add_line(param_line)
    column_width        = []
    column_description  = []
    param_line.each do |k,v|
      if k.to_s.starts_with?("column_") && !v.blank?
        column_width << v.to_i
        column_description << param_line[k.to_s.gsub('column_','columntext_')]
      end         
    end
    sum = column_width.inject{|sum_w,x| sum_w + x }
    self.errors.add('base',"La somme des largeurs doit être égale à 12".trn) unless sum == 12
    if self.errors.empty?
      template_line = EsTemplateLine.create({:num => 9999,:es_template_id => self.id})
      column_width.each_with_index do |width,i|
        EsTemplateCol.create({:num => i+1,:es_template_line_id => template_line.id, :width => width, :description => column_description[i]})
      end      
      self.compress_line
    end
    
  end


  
  def save_design(containers)
#    template_cols = []
#    self.es_template_lines.each do |l|
#      template_cols += l.es_template_cols.map(&:id)
#    end
    containers.each do |num_part,container|
      container.each do |container_name,part_caract|
        part_id = container_name[14..-1]
        if num_part.to_i==0
          col_id  = 0
        else
#          col_id  = template_cols[num_part.to_i - 1]
          col_id  = part_caract[:col_id]
        end
        part = EsPart.find_by_id(part_id)
        part.update_attributes({:es_template_col_id => col_id, :num => part_caract[:num_row]})
      end
    end
  end
  
  def self.load_template_file
    template_files = []
    tmp_dir = File.join(Rails.root,"app","views","templates")
    Dir.entries(tmp_dir).each do |file|
      if File.file?(File.join(tmp_dir, file)) && (File.extname(file)=='.erb' && file.starts_with?('_'))
        template_files << File.join("templates", file)
        name = file.split('.')[0][1..-1]
        EsTemplate.create(:name => name, :description => "Fichier template '%{temp}'".trn(:temp => name), :validated => 'N', :es_category_id => 0,:template_type => 'TEMPLATE')  unless EsTemplate.where(:name => name).first
      end
    end
    template_files
  end


end