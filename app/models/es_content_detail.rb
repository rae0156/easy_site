# encoding: UTF-8

class EsContentDetail < ActiveRecord::Base

  belongs_to :es_content
  belongs_to :es_module
  has_many :es_content_detail_params, :order => "sequence"
  has_many :es_content_detail_elements, :order => "num"
  belongs_to :es_content_detail_element_parent, :foreign_key => "es_content_detail_element_parent_id", :class_name => "EsContentDetailElement"

  acts_as_multi_site
  attr_accessible :sequence, :es_content_id, :content, :editable, :content_type, :name, :module_action_name, :es_content_detail_element_parent_id
#  acts_as_dynamic_model 
 
  validates_presence_of :content_type, :message => '#' + 'Le type de contenu est obligatoire'.trn
  validates_uniqueness_of :es_content_id, :message => "#" + "Ce nom de contenu existe déjà".trn,:scope => [:es_content_detail_element_parent_id,:sequence,:es_site_id]
  validates_presence_of :module_action_name, :message => '#' + "Une action de module est obligatoire".trn, :if => Proc.new { |f|  f.content_type==EsContent::CONTENT_TYPES_MODULE }
    
  before_destroy :check_dependances
  
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  
  
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_content => :name,:es_module => :setup_name },
                  :model_audit_label  => "Détail de contenu".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    (self.es_content ? self.es_content.name : (self.es_content_detail_element_parent ? self.es_content_detail_element_parent.name : "")) + " " + self.sequence.to_s
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
      setup = self.es_content_detail_params.find_by_setup_name(k) 
      setup.update_attribute("value",v) if setup
    end
  end

  
  def check_dependances
    unless self.es_content_detail_params.empty?
      #self.errors.add("base", "Impossible de supprimer ce contenu, parce qu'il est a des assigné à des paramètres".trn)
      self.es_content_detail_params.destroy_all
    end
    #ne pas deleter .es_content_detail_element_parent_id, car on bouclerait entre es_content_detail_element_parent et es_content_detail_child_id 
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

  # dans la creation - parties disponnibles
  def generate_contain_available(mode_normal=true)
    return generate_contain(self.id, :parent => "available", :mode_normal => mode_normal) 
  end

  # dans la creation - parties placées
  def generate_contain_organised(mode_normal=true)
    return generate_contain(self.id, :parent => "organised", :mode_normal => mode_normal) 
  end

  # dans les templates
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
  
  def add_element(element_type,options)
    
    module_action_name  = options[:module_action_name].presence || ""
    structured_parent   = options[:strutured_parent].presence || ""
    table_col           = options[:table_col].presence || ""
    table_lin           = options[:table_lin].presence || ""
    
    last = self.es_content_detail_elements.find(:last,:conditions => {:parent_id => -1},:order => 'num')
    num = (last ? last.num : 0) + 1 
    element = EsContentDetailElement.create(:element_type => element_type, :name => "9999999999", :description => "/", :parent_id => -1, :num => num, :es_content_detail_id => self.id)
    element.update_attributes({:name => "#{element_type}_#{element.id}", :description => "#{element_type} #{element.id}"})

    case element_type
      when 'module'
        create_module_content_for_element(module_action_name,element)
      when 'structured'
        create_structured_content_for_element(structured_parent,element)
      when 'table'
        create_table_content_for_element(table_col,table_lin,element)
    end

  end
  
private

   def create_table_content_for_element(table_col,table_lin,element)
      if !table_col.blank? && !table_lin.blank? && element
        
        (1..(table_col.to_i*table_lin.to_i)).to_a.each do |num|
          element_1 = EsContentDetailElement.create(:element_type => "structured_child", :name => "9999999999", :description => "/", :parent_id => element.id, :num => num, :es_content_detail_id => self.id)
          element_1.update_attributes({:name => "#{element_1.element_type}_#{element_1.id}", :description => "#{element_1.element_type} #{element_1.id}"})
        end
        
        element_1 = EsContentDetailElementTable.find_by_id(element.id)
        element_1.update_attributes({:nbr_column => table_col, :nbr_line => table_lin})
      end
   end

   def create_structured_content_for_element(structured_parent,element)
      if !structured_parent.blank? && element
        
        structured_parent.split('+').each_with_index do |c,i|
          element_1 = EsContentDetailElement.create(:element_type => "structured_child", :name => "9999999999", :description => "/", :parent_id => element.id, :num => i+1, :es_content_detail_id => self.id)
          element_1.update_attributes({:name => "#{element_1.element_type}_#{element_1.id}", :description => "#{element_1.element_type} #{element_1.id}"})
        end
        
        element_1 = EsContentDetailElementStructured.find_by_id(element.id)
        element_1.update_attributes({:structure_type => structured_parent})
      end
   end

   def create_module_content_for_element(module_action_name,element)
      if !module_action_name.blank? && element
        description = "Module".trn + " #{module_action_name}" + " #{Time.zone.now.strftime("%d%m%Y %H%M%S")}"
        name = description.gsub(' ', '_').downcase
        detail = EsContentDetail.new(:sequence => 1, :es_content_id => nil, :es_content_detail_element_parent_id => element.id, :content => "", :editable => "N", :content_type => "module", :module_action_name => module_action_name)
        detail.save
        element.update_attribute('es_content_detail_child_id',detail.id)
        module_action_name_array = module_action_name.split(' ')
        detail.create_module_params(EsModule.get_module_params(module_action_name_array[0],module_action_name_array[1]))  
      end
   end

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
      categories  = ['taille/marge','taille/espace',"taille/dimension","présentation/affichage","présentation/couleurs"]
       
      element     = generate_element(p)

      #init_style  = normal ? "" : ("display:" + (["image","link"].include?(p.element_type)  ? "inline-block" : "block") + ";position:relative;")
      init_style  = "display:" + (["image","link"].include?(p.element_type) || get_property(element,'parent_style') == 'span' ? "inline-block" : "block") + ";position:relative;"
      init_style += ("border: 1px solid #{(get_property(element,'border_color','black'))};") if get_property(element,'border_available','N') == 'Y'

      properties  = EsContent.prepare_properties(element,categories,{:id => "element_part_#{p.id}", :style => init_style})
      element_part = generate_element_part(element,normal)

      parent_style = (properties.delete(:parent_style) || 'div').to_sym
      clear_float = (properties.delete(:cancel_float) || 'N')=='Y'
      if normal
        text_part   = element_part
      else
        btns  = ""
        btns  +=    generate_tag(:a, 
                            #url_for(:controller => "es_templates" , :action => "edit_part", :id => p.id),
                            generate_tag(:i, "", :class=>"glyphicon glyphicon-edit").html_safe,
                            {
                            :title =>"Modifier cette partie".trn,
                            :class => 'edit_element',
                            :href => '#', 
                            "data-reference" => p.id
                            }
                           ) + " "
        btns  +=    generate_tag(:a, 
                            #url_for(:controller => "es_templates" , :action => "delete_part", :id => p.id, :sub_action => "destroy"),
                            generate_tag(:i, "", :class=>"glyphicon glyphicon-remove").html_safe,
                            {
                            :title =>"Supprimer cette partie".trn,
                            #Pas besoin de confirmation, car pris en charge par le javascript
                            #"data-confirm" =>"Voulez vous vraiment supprimer cette partie ?".trn,
                            :class => 'delete_element',
                            :href => '#', 
                            "data-reference" => p.id
                            }
                          ) + " "

        
        
        
        
        text_part   = generate_tag(:div, generate_tag(:span, btns + p.name,{:style => "display:none;", :class => "dyn_options"}), {:class => "label label-info label-info-hiden", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                      element_part
      end
      text_part   = generate_tag(parent_style, text_part, properties)
      text_part   += "<DIV style='clear: both;'></DIV>" if clear_float
      text       += text_part
    end 
    

    if !normal
      if parent_id<=0
        text = generate_tag(:div, "<br/>" + text, {:style => "border:1px solid red;", :class => "row"}) 
        text = generate_tag(:div, text, {:class => "drag_drop_template",:style => "height:auto;"} )
      else
        text = generate_tag(:span, "&nbsp;".html_safe) + text  #necessaire pour drag and drop
      end      
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
      unless tmp_url.blank?
        html_text   = generate_tag(:IMG, "", {:src=>tmp_url, :style => 'width: 100%;'})
         
        if get_property(tmp_element,"link_available",'N') == 'Y'
          html_text=generate_tag(:A,html_text, {:href=>tmp_url, :target => "_blank"}) 
        end
        
      else
        html_text   = "Choisir une image".trn
      end
    when "link"
      tmp_text    = get_property(tmp_element,"link_text","Lien".trn)
      tmp_url     = get_property(tmp_element,"link")
      target      = get_property(tmp_element,"target","same")=='new' ? "_blank" : "_self"
      tmp_url     = ((tmp_url.downcase.starts_with?('http://') || tmp_url.downcase.starts_with?('https://')) ? '' : "http://") + tmp_url
      html_text   = generate_tag(:a, tmp_text, {:href => tmp_url, :target => target})
    when "text"
      tmp_text    = get_property(tmp_element,"text","Texte".trn)
      html_text   = tmp_text.gsub(/\n/,"<BR>") #generate_tag(:p, tmp_text).gsub(/\n/,"<BR>")
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
      tmp_url     = get_property(tmp_element,"link")
      target      = get_property(tmp_element,"target","same")=='new' ? "_blank" : "_self"
      tmp_content = generate_tag(:a, tmp_content, {:href => tmp_url, :target => target}) unless tmp_url.blank?
      if normal
        html_text   = tmp_content
      else
        #tmp_content = generate_tag(:span, "&nbsp;".html_safe) + tmp_content  #necessaire pour drag and drop
        style = "border:1px dashed #000;"
        tmp_class = "drag_drop_template"
        html_text   = generate_tag(:div, generate_tag(:div, tmp_content,:parent_id => tmp_element.id),:class => tmp_class,:style => style)
      end
    when "article"
      is_visible = tmp_element.is_visible?
      if normal
        tmp_content = is_visible ? generate_contain(self.id, :parent_id => tmp_element.id, :mode_normal => normal) : ""
        html_text   = tmp_content
      else
        tmp_content = (is_visible ? '' : generate_tag(:div,"Cet article ne sera pas visible".trn)) + generate_contain(self.id, :parent_id => tmp_element.id, :mode_normal => normal)
        style = "border:1px dashed #000;"
        tmp_class = "drag_drop_template"
        html_text   = generate_tag(:div, generate_tag(:div, tmp_content,:parent_id => tmp_element.id),:class => tmp_class,:style => style)
      end
    when "module"
      unless tmp_element.es_content_detail_child_id.nil?
        tmp_es_content_detail = EsContentDetail.find_by_id(tmp_element.es_content_detail_child_id)
        html_text   = generate_tag(:DIV, tmp_es_content_detail.content)
      else
        html_text   = generate_tag(:DIV, "Il y a un problème avec l'élément %{name}".trn(:name => self.name))
      end

    when "structured"

      cols_a = tmp_element.structure_type.split('+')
      html_text=""
      cols_a.each_with_index do |c,i|
        tmp_element_1= EsContentDetailElement.find(:first,:conditions=> {:parent_id => tmp_element.id, :num => i+1})
        if tmp_element_1
          tmp_content = generate_contain(self.id, :parent_id => tmp_element_1.id, :mode_normal => normal)
          unless normal
            style = "border:1px dashed #000;"
            tmp_class = "drag_drop_template"
            tmp_content = generate_tag(:div, generate_tag(:div, tmp_content,:parent_id => tmp_element_1.id),:class => tmp_class,:style => style)
          end
          html_text   +=  generate_tag(:DIV, tmp_content,{:class => "col-md-#{c}"})
        end
      end
      html_text   = generate_tag(:DIV, html_text,{:class => "row"})

    when "table"

      col  = tmp_element.nbr_column.to_i
      line = tmp_element.nbr_line.to_i
      html_text=""
      i=0      
      (1..line).to_a.each do |l|
        html_text_line = ""
        (1..col).to_a.each do |c|
          i+=1
          tmp_element_1= EsContentDetailElement.find(:first,:conditions=> {:parent_id => tmp_element.id, :num => i})
          if tmp_element_1
            tmp_content = generate_contain(self.id, :parent_id => tmp_element_1.id, :mode_normal => normal)
            tmp_content = ("&nbsp;" * 5) if tmp_content.blank?          
            unless normal
              style = "border:1px dashed #000"
              tmp_class = "drag_drop_template"
              tmp_content = generate_tag(:div, generate_tag(:div, tmp_content,:parent_id => tmp_element_1.id),:class => tmp_class,:style => style)
            end
            html_text_line += generate_tag(:TD, tmp_content)
          end
        end
        html_text += generate_tag(:TR, html_text_line)
      end
      html_text   = generate_tag(:TABLE, html_text,{:style=> "width:100%;"})

    else
      html_text = generate_tag(:p, tmp_element.element_type)
    end
    
    return html_text
    
  end

  def get_property(element,property,default="")
    return (element.respond_to?(property) ? element.send(property) : nil)||default    
  end
  
end