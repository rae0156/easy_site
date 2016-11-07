# encoding: UTF-8

class EsPart < ActiveRecord::Base
  belongs_to :es_template
  belongs_to :es_template_col
  belongs_to :es_content
  belongs_to :es_site
  
  acts_as_dynamic_model([
                          {order: 3,
                           name: "es_template_id",
                           column_name:"template name",
                           type: "integer",
                           foreign: true, 
                           linked_name: "es_template",
                           model_linked: "EsTemplate",
                           display_new: true,
                           display_edit: true,
                           print: true,
                           link_update: false,
                           search: false,
                           dynamic_filter: true,
                           dynamic_search: true,
                           sort: true
                          },
                          {order: 5,
                           name: "es_template.description",
                           column_name:"template description",
                           type: "string",
                           foreign: false, 
                           linked_name: nil,
                           model_linked: nil,
                           display_new: true,
                           display_edit: true,
                           display_list: true,
                           print: true,
                           link_update: false,
                           search: false,
                           dynamic_filter: false,
                           dynamic_search: false,
                           sort: true
                          },
                          {order: 6,
                           name: "es_template.es_category.name",
                           column_name:"category name",
                           type: "string",
                           foreign: false, 
                           linked_name: nil,
                           model_linked: nil,
                           display_new: true,
                           display_edit: true,
                           display_list: true,
                           print: true,
                           link_update: false,
                           search: false,
                           dynamic_filter: true,
                           dynamic_search: true,
                           sort: true
                          },
                          {order: 7,
                           name: "created_at",
                           column_name:"creation",
                           display_new: true,
                           display_edit: true,
                           display_list: true,
                           search: true,
                           dynamic_filter: true,
                           dynamic_search: true
                          }    
                        ],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name, :es_content => :name, :es_site => :code},
                  :model_audit_label  => "Parties de template".trn,
                  :process_label      => "Changement manuel".trn
 
  before_validation :fill_description
 
 
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
      if self.es_template.is_dynamic
        return nil
      elsif EsPart.is_dynamic(self.name)
        return 'Dynamique - template fichier'.trn
      else
        return 'Fichier'.trn
      end
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
      return true if cd.editable=='Y' && cd.content_type==EsContent::CONTENT_TYPES_FREE
    end if self.es_content
    editable
  end

  def type_of_part
    return !self.is_dynamic ? "Fichier".trn : "Dynamique".trn
  end
  
  def content_type
    if self.es_content && self.es_content.es_content_details.size>0
      self.es_content.es_content_details.first.content_type
    else
      ""
    end
  end
  
  def self.get_name_list(type_content=['part','content'])
    name_list = []
    files_list = Dir.glob("#{Rails.root}/app/views/parts/_part_*.html.erb").map{|f| File.basename(f,".html.erb")[1..-1]}
    if type_content.include?('part')
      files_list.sort.each do |f|
        name_list << ["Fichier : %{name}".trn(:name => f[5..-1]),f]
      end
    end    

    if type_content.include?('content')
      EsContent.all(:order => "name").each do |c|
        name_list << ["Contenu : %{name}".trn(:name => c.name),c.name] unless files_list.include?(c.name)
      end
    end
    
    return name_list
  end

  def fill_description
    self.description = "Contenu '%{content}' pour le template '%{template}'".trn(:content => self.name, :template => self.es_template.name) if self.description.blank?    
  end
    
  
  
end