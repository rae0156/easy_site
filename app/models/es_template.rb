# encoding: UTF-8

class EsTemplate < ActiveRecord::Base

  has_many :es_pages
  has_many :es_parts
  has_many :es_template_lines, :order => "num"
  belongs_to :es_category

  acts_as_multi_site
  attr_accessible :name, :es_category_id, :description
#  acts_as_dynamic_model 
 
  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :description, :message => '#' + 'La description est obligatoire'.trn
  validates_presence_of :es_category_id, :message => '#' + 'La catégorie est obligatoire'.trn
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
  
  def is_dynamic
    return !File.exist?("#{Rails.root}/app/views/templates/_#{self.name}.html.erb")
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

  

  def generate_template_for_render(parts_containt)
    text = generate_lines(self.id,0,{:empty => false,:drag_drop => false, :parts_containt => parts_containt})
    return text.html_safe
  end



  def generate_design_empty
    text = generate_lines(self.id,0,{:empty => true,:drag_drop => true})
    return text.html_safe
  end

  def generate_design_with_part
    text = generate_lines(self.id,0,{:empty => false,:drag_drop => true})
    return text.html_safe    
  end

  def generate_design_part_available
    parts = EsPart.all(:conditions => {:es_template_id => self.id})
    
    text = generate_tag(:p, "Partie(s) non placée(s) dans le template".trn)
    parts.each_with_index do |p,i|
      if (p.es_template_col_id.blank? || p.es_template_col_id == 0)
        text_col   = generate_tag(:div, p.name, {:class => "label label-info"}) + \
                     generate_tag(:div, p.description)
        text_col   = generate_tag(:div, text_col, {:id => "template_part_#{p.id}"})
        text       += text_col
      end 
    end 
    text = generate_tag(:div, text, {:class => "col-md-12",:style => "border:1px solid red;padding:5px;"})
    text = generate_tag(:div, text, {:class => "row drag_drop_template"})      

    return text.html_safe
  end
  
  
  def save_design(containers)
    template_cols = []
    self.es_template_lines.each do |l|
      template_cols += l.es_template_cols.map(&:id)
    end
    containers.each do |num_part,container|
      container.each do |container_name,part_caract|
        part_id = container_name[14..-1]
        if num_part.to_i==0
          col_id  = 0
        else
          col_id  = template_cols[num_part.to_i - 1]
        end
        #puts "ici 1000 : #{part_id} #{part_caract[:num_row]} #{col_id}"
        EsPart.find(part_id).update_attributes({:es_template_col_id => col_id, :num => part_caract[:num_row]})
      end
    end
  end
  
  

private

  def generate_lines(template_id, parent_id,options={})
    empty          = options[:empty].presence
    empty          = false if empty.nil?
    dr_dr          = options[:drag_drop].presence
    dr_dr          = false if dr_dr.nil?
    parts_containt = options[:parts_containt].presence||{}
    
    text = ""
    tmp_lines = EsTemplateLine.all(:conditions => {:es_template_id => template_id, :es_col_parent_id => parent_id}, :order => "num")  
    tmp_lines.each_with_index do |l,y|
      text_line = ""
      l.es_template_cols.each_with_index do |c,x|
        if dr_dr
          text_col = c.description.blank? ? "ligne %{line} colonne %{col}".trn(:line => y + 1, :col => x + 1) : c.description.limit(30)
          text_col = generate_tag(:p, text_col)
        else
          text_col = ""
        end
        unless empty
          c.es_parts.order('num').each do |p|
            if dr_dr
              text_part = generate_tag(:div, p.name, {:class => "label label-info"}) + \
                          generate_tag(:div, p.description)
                          
              text_part = generate_tag(:div, text_part, {:id => "template_part_#{p.id}"})
            else
              text_part = parts_containt[p.name].presence || ""
            end
            text_col += text_part            
          end
        end
        tmp_style = dr_dr ? "border:1px solid red;padding:5px;" : ""
        
        properties = EsContent.prepare_properties(c,{:class => "col-md-#{c.width}",:style => tmp_style})
        text_line += generate_tag(:div, text_col, properties)
      end 
      tmp_class = dr_dr ? "row drag_drop_template" : "row"
      properties = EsContent.prepare_properties(l,{:class => tmp_class})
      text += generate_tag(:div, text_line, properties)      
    end
    text = generate_tag(:div, text, {:class => "container"}) unless dr_dr
    return text
  end
end