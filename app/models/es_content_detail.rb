# encoding: UTF-8

class EsContentDetail < ActiveRecord::Base

  belongs_to :es_content
  belongs_to :es_module
  has_many :es_content_detail_params, :order => "sequence"
  has_many :es_content_detail_elements, :order => "num"

  acts_as_multi_site
  attr_accessible :sequence, :es_content_id, :content, :editable, :content_type, :name, :module_action_name
#  acts_as_dynamic_model 
 
  validates_presence_of :content_type, :message => '#' + 'Le type de contenu est obligatoire'.trn
  validates_uniqueness_of :es_content_id, :message => "#" + "Ce nom de contenu existe déjà".trn,:scope => [:sequence,:es_site_id]
  validates_presence_of :module_action_name, :message => '#' + "Une action de module est obligatoire".trn, :if => Proc.new { |f|  f.content_type==EsContent::CONTENT_TYPES_MODULE }
    
  before_destroy :check_dependances
  
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  
  
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_content => :name,:es_module => :setup_name },
                  :model_audit_label  => "Détail de contenu".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.es_content.name + " " + self.sequence.to_s
  end
  
  def create_module_params(module_params)
    existing_values={}
    self.es_content_detail_params.each do |p|
      existing_values[p.setup_name] = p.value
    end

    self.es_content_detail_params.destroy_all
    module_params.each_with_index do |p,i|
      tmp_attributes = p.attributes.except("path_setup","id","module_name")
      tmp_attributes["sequence"] = i 
      tmp_attributes["value"]    = existing_values[tmp_attributes["setup_name"]] if existing_values[tmp_attributes["setup_name"]].present?   
      param = EsContentDetailParam.new(tmp_attributes)
      self.es_content_detail_params << param
    end
    
    module_action_name = self.module_action_name.split(' ')
    self.content = "<%= generate_module_part(" + '"' + module_action_name[0] + '","' + module_action_name[1] + '"' + ",#{self.id})%>"
    self.save
  end

  def save_module_params(module_params)
    module_params.each do |k,v|
      self.es_content_detail_params.find_by_setup_name(k).update_attribute("value",v)
    end
  end

  
  def check_dependances
    unless self.es_content_detail_params.empty?
      #self.errors.add("base", "Impossible de supprimer ce contenu, parce qu'il est a des assigné à des paramètres".trn)
      self.es_content_detail_params.destroy_all
    end
    return (self.errors.empty?)
  end


  def name=(name)    
    self.es_content.name=name
  end

  def name
    return self.es_content.blank? ? "" : self.es_content.name
  end


  def used?
    return self.es_content.used?
  end

  def content_detail_name
    "Elément numéro %{num}".trn(:num => self.sequence.to_i) 
  end

  def generate_contain_available(mode_normal=true)
    return generate_contain(self.id, :parent => "available", :mode_normal => mode_normal) 
  end

  def generate_contain_organised(mode_normal=true)
    return generate_contain(self.id, :parent => "organised", :mode_normal => mode_normal) 
  end

  def generate_contain_template(mode_normal=true)
    return generate_contain(self.id, :parent => "organised", :mode_normal => mode_normal) 
  end
  
  def save_design(containers)
    containers.each do |num_part,container|
      container.each do |container_name,part_caract|
        part_id = container_name[13..-1]
        parent_id = part_caract[:parent_id].blank? ? (part_caract[:num_part]=='1' ? -1 : 0) : part_caract[:parent_id]
        EsContentDetailElement.find_by_id(part_id).update_attributes({:es_content_detail_id => self.id, :parent_id => parent_id, :num => part_caract[:num_row]})
      end
    end
  end
  
  def add_element(element_type)
    last = self.es_content_detail_elements.find(:last,:conditions => {:parent_id => -1},:order => 'num')
    num = (last ? last.num : 0) + 1 
    element = EsContentDetailElement.create(:element_type => element_type, :name => "9999999999", :description => "/", :parent_id => -1, :num => num, :es_content_detail_id => self.id)
    element.update_attributes({:name => "#{element_type}_#{element.id}", :description => "#{element_type} #{element.id}"})
  end
  
private

  def generate_contain(content_detail_id, options = {})
    parent      = options[:parent]||'organised'
    normal      = options[:mode_normal].nil? ? true : options[:mode_normal]
    return '' if normal && parent == 'available'
    pre_text    = ""
    parent_id   = options[:parent_id]||(parent=='available' ? -1 : 0)
    if parent == "available"
      pre_text  = generate_tag(:p, "Partie(s) non placée(s)".trn) + generate_tag(:p, "Faites glisser les éléments disponnibles ci-dessous dans la partie inférieure".trn)
    end
    
    parts       = EsContentDetailElement.all(:conditions => {:es_content_detail_id => content_detail_id, :parent_id => parent_id}, :order => "num")
    text        = pre_text
    parts.each_with_index do |p,i|
      tmp_display = ["image","link"].include?(p.element_type) ? "inline-block" : "block" 
      categories  = ['taille/marge','taille/espace',"présentation/affichage"]
      
      element     = generate_element(p)
      properties  = EsContent.prepare_properties(element,categories,{:id => "element_part_#{p.id}", :style => "display:#{tmp_display};position:relative;"})    
      element_part = generate_element_part(element,normal)

      if normal
        text_part   = element_part
      else
        text_part   = generate_tag(:div, generate_tag(:a, p.name,{:class => 'edit_element', :href => '#', "data-reference" => p.id}), {:class => "label label-info", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                      element_part
      end
      text_part   = generate_tag(:div, text_part, properties)

#        text_part   = generate_tag(:div, generate_tag(:a, p.name,{:class => 'edit_element', :href => '#', "data-reference" => p.id}), {:class => "label label-info"}) + \
#                      generate_tag(:div, p.description + (normal ? ' [NORMAL]' : ''))
#        text_part   = generate_tag(:div, text_part, {:id => "element_part_#{p.id}"})
      
                    
      text       += text_part
    end 
    

#      text = generate_tag(:div, text, {:class => "col-md-12",:style => "padding:5px;"}) 
#      text = generate_tag(:div, text, {:class => "row"})      
    if !normal && parent_id<=0
      text = generate_tag(:div, "<br/>" + text, {:style => "border:1px solid red;"}) #padding:5px;
      text = generate_tag(:div, text, {:class => "drag_drop_template"})      
    end
    return text.html_safe


  end  

  def generate_element(element)
    begin
      tmp_element = "EsContentDetailElement#{element.element_type.classify}".constantize.find_by_id(element.id)
    rescue 
      tmp_element = nil
    end
    return tmp_element
  end

  def generate_element_part(tmp_element, normal)
    case tmp_element.element_type
    when "image"
      tmp_url     = get_property(tmp_element,"image")
      tmp_url     = tmp_url[6..-1] if tmp_url.starts_with?('public/')
      html_text   = generate_tag(:IMG, "", {:src=>tmp_url})
    when "link"
      tmp_text    = get_property(tmp_element,"link_text","Lien".trn)
      tmp_url     = get_property(tmp_element,"link")
      tmp_url     = ((tmp_url.downcase.starts_with?('http://') || tmp_url.downcase.starts_with?('https://')) ? '' : "http://") + tmp_url
      html_text   = generate_tag(:a, tmp_text, {:href => tmp_url})
    when "text"
      tmp_text    = get_property(tmp_element,"text","Texte".trn)
      html_text   = generate_tag(:p, tmp_text).gsub(/\n/,"<BR>")
    when "video"
      tmp_url     = get_property(tmp_element,"video")
      if File.file?(File.join(Rails.root,tmp_url))
        tmp_file  = tmp_url.downcase.starts_with?('public/') ? tmp_url[6..-1] : tmp_url
        html_text = "<embed src='#{tmp_file}' width='400' height='400'></embed>"        
      else
        html_text = generate_tag(:DIV, "Le fichier vidéo '%{url}' n'est pas correcte".trn(:url => tmp_url)).html_safe 
      end
    when "free"
      tmp_text    = get_property(tmp_element,"free_content","Contenu libre".trn)
      html_text   = generate_tag(:DIV, tmp_text.html_safe)
    when "parent"
      tmp_content = generate_contain(self.id, :parent_id => tmp_element.id, :mode_normal => normal)
      if normal
        style = ""
        tmp_class = ""
      else
        tmp_content = generate_tag(:p, "&nbsp;".html_safe) + tmp_content
        style = "background-color:#777;padding:5px;"
        tmp_class = "drag_drop_template"
      end
      html_text   = generate_tag(:DIV, generate_tag(:DIV, tmp_content,:parent_id => tmp_element.id),:class => tmp_class,:style => style)
    else
      html_text = generate_tag(:p, tmp_element.element_type)
    end
    
    return html_text
    
  end

  def get_property(element,property,default="")
    return (element.respond_to?(property) ? element.send(property) : nil)||default    
  end
  
end