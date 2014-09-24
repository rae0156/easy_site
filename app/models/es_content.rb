# encoding: UTF-8

class EsContent < ActiveRecord::Base

  EDITABLE_CONTENT_TYPES  = ["free"]
  CONTENT_TYPES_MODULE    = "module"
  CONTENT_TYPES           = ["module","free"]

  has_many :es_content_details, :order => "sequence"
  has_many :es_parts
  acts_as_dynamic_model  
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  

  def compress_detail
    self.es_content_details.each_with_index do |l,i|
      l.update_attribute("sequence",i+1)
    end
  end

  def used?
    return self.es_parts.size > 0
  end

  def self.delete_all_properties(element_type, element_id)
    begin
        model_class = element_type.constantize
    rescue 
    end

    if class_exists?(element_type.to_s)
      element       = model_class.find(element_id)
      element.dyn_attributes.destroy_all
    end    
  end

  def self.get_properties(element_type, element_id,init_properties={})
    tabs= get_properties_detail(element_type, element_id,init_properties)
    return tabs
  end

  def self.save_properties(element_type, element_id, properties)
    return_element      = EsContent.new 

    begin
        model_class = element_type.constantize
    rescue 
    end

    if class_exists?(element_type.to_s)
      element       = model_class.find(element_id)
      unless element.blank?
        properties.each do |p_name,v|
          if v.blank?
            element[p_name.to_sym]=nil
          else
            element[p_name.to_sym]= v
          end             
        end
        element.save
        element.errors.full_messages.each do |m|
          return_element.errors.add(:base, m) 
        end
      end
    else
      return_element.errors.add(:base, "Le type d'élément '%{name}' n'existe pas".trn(:name => element_type)) 
    end
    return return_element
  end

  def self.prepare_properties(element,properties={})
    if element.has_dyn_attributes?
      element.dyn_attributes.each do |da|
        css_attr,css_add,css_delimiter,css_value = prepare_one_properties(da.dyn_attribute_type.name,da.value)
        if css_add
          tmp_values  = properties[css_attr.to_sym].presence||""
          tmp_values += css_delimiter unless tmp_values.blank?
          tmp_values += css_value
        else
          tmp_values  = css_value
        end
        properties[css_attr.to_sym] = tmp_values
      end
    end
    return properties
  end


private

  def self.prepare_one_properties(name,value)
    
    tmp_css_attr      = "style"
    tmp_css_value     = "#{name}:#{value}"
    tmp_css_delimiter = ";"
    tmp_add           = true
    
    case name
      when "url_image"
        value = value[6..-1] if value.starts_with?('public/')
        tmp_css_value = "background-position:center center;background-repeat:no-repeat;background-image:url(#{value})"
      when "header"
        tmp_css_attr      = "class"
        tmp_css_delimiter = " "
        tmp_css_value     = value
      when "alert"
        tmp_css_attr      = "class"
        tmp_css_delimiter = " "
        tmp_css_value     = "alert-#{value}"
      else
        if name.starts_with?( 'padding-', 'margin-')
            tmp_css_value     = "#{name}:#{value}px"
        end
    end


    return tmp_css_attr,tmp_add,tmp_css_delimiter,tmp_css_value
  end

  def self.get_properties_detail(element_type, element_id,init_properties)
    tmp_tabs = {}
    tmp_info_tabs   = {}

    DynAttributeType.all(:conditions => ["attribute_type = ?", element_type]).each do |at|
      category = at.category.split('/')

      
      new_tab = !tmp_info_tabs[category[0]].present?
      tmp_info_tabs[category[0]] = {:tab_num => tmp_info_tabs.size + 1} if new_tab
      num_tab = tmp_info_tabs[category[0]][:tab_num]
      new_group = !tmp_info_tabs[category[0]][category[1]].present? 
      tmp_info_tabs[category[0]][category[1]] = {:group_num => tmp_info_tabs[category[0]].size} if new_group
      num_group = tmp_info_tabs[category[0]][category[1]][:group_num]


      
      tmp_tabs[category[0]]={:title => category[0].trn} if new_tab        
      if new_group
        tmp_tabs[category[0]]["title_#{num_group}".to_sym]=category[1].trn 
        tmp_tabs[category[0]]["group_#{num_group}".to_sym]=[]
      end
      tmp_value = !init_properties[at.name].nil? ? init_properties[at.name] : (element_type.constantize.find(element_id)[at.name] || at.default_value)
      tmp_tabs[category[0]]["group_#{num_group}".to_sym]  << add_property(at.name   , tmp_value  , :description => at.comments, :format => at.type_data, :read_only => 'N', :addon_params => at.type_param, :value_list => (at.choices || "").split(','))

    end if class_exists?(element_type.to_s)


    tabs =[]
    tmp_tabs.each do |k,v|
      tabs << v
    end
    return tabs
    
  end

  def self.add_property(name, value = "",options = {})
    options[:description] ||= ""
    options[:format]      ||= "string"
    options[:mandatory]   ||= "N"
    options[:read_only]   ||= "N"
    value=value.split(",") if options[:format] == "multiple_list"
    return {:name => name ,:description=>options[:description].trn  ,:format => options[:format], :value => value,:read_only => options[:read_only], :mandatory => options[:mandatory], :value_list => options[:value_list] , :addon_params => options[:addon_params] }
  end  

end