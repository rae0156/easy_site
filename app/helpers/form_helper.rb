# encoding: UTF-8

module FormHelper

  def easy_generate_form(tabs=[])
    text_list = ""
    text_content = ""
    nbr_tab = 0
    if tabs.is_a?(Array)
      tabs.each_with_index do |o,i|
        title = o[:title].presence || "Titre inconnu".trn
        tab = easy_generate_tab(o)
        unless tab.blank?
          nbr_tab += 1
          text_list += generate_tag(:li, generate_tag(:a, title, {:href => "#tab_#{i}","data-toggle".to_sym=>"tab"}), {:class => (i==0 ? "active" : "" )})
          text_content += generate_tag(:div, tab, {:id => "tab_#{i}", :class => (i==0 ? "tab-pane fade in active" : "tab-pane fade" )})
        end
      end
    end
    
    if nbr_tab > 1
      text_list     = generate_tag(:ul, text_list, {:class => "nav nav-tabs"})    unless text_list.blank?
      text_content  = generate_tag(:div, text_content, {:class => "tab-content"}) unless text_content.blank?
    else
      text_list     = ""
    end
    (text_list + text_content).html_safe
  end
  
  def easy_generate_tab(tab={})
    text        = ""
    text_array  = []
    title_group = []
    if tab.is_a?(Hash)     
      tab.select {|k,v| k.to_s.start_with?("group_")}.sort_by{|k,v| k.to_s}.each do |k,v|
        group       = easy_generate_group(v)
        unless group.blank?
          title_group << (tab[("title_" + k.to_s[6..-1]).to_sym].presence || "".trn)
          text_array << group
        end
      end
    end
    
    if text_array.size > 0
      text_array.each_with_index do |tmp,i|
        text += (title_group[i].blank? ? "" : generate_tag(:DIV, title_group[i], {:class => "panel-heading"})) + generate_tag(:DIV, tmp, {:class => "panel-body"})
      end
      text = generate_tag(:DIV, text, {:class => "panel panel-primary"})  
    end
    
    return text.html_safe
  end
  
  def easy_generate_group(group=[])
    text=""
    if group.is_a?(Array)
      group.each do |element|
        text += easy_generate_element(element)
      end
    end
    return text
  end
  
  def easy_generate_element(element={})
    text=""
    if element.is_a?(Hash)
      name        = element[:name].presence        || ""
      unless name.blank?
        description = element[:description].presence || ""
        description += " : " unless description.blank?
        value       = element[:value].presence || ""
        format      = element[:format].presence || ""
        read_only   = (element[:read_only].presence||"N")=='Y'
        mandatory   = (element[:mandatory].presence||"N")=='Y'
        value_list  = element[:value_list].presence || []
        value_list.reject!(&:empty?) unless value_list.blank?
        addon_param = element[:addon_params].presence || ""
        span_size   = 9
        case format
        when "link"
          text = link_to(value, url_for(addon_param))
        when "string"
          text = easy_tag('text',:instance => "generated", :field => name,:value=> value, :read_only=> read_only)
        when "long_string"
          text = easy_tag('long_text',:instance => "generated", :field => name,:value=> value, :read_only=> read_only,:cols=> 100)
        when "list"
          text = easy_tag('list',:instance => "generated", :field => name,:selected_value=> value, :read_only=> read_only,:value_list_array => value_list.uniq,:multiple => false)
        when "multiple_list"
          text = easy_tag('list',:instance => "generated", :field => name,:selected_value=> value, :read_only=> read_only, :number_of_line => 5, :value_list_array => value_list,:multiple => true)
        when "integer"
          text = easy_tag('integer',:instance => "generated", :field => name,:value=> value, :read_only=> read_only)
          span_size = 2
        when "decimal"
          text = easy_tag('decimal',:instance => "generated", :field => name,:value=> value, :read_only=> read_only)
          span_size = 2
        when "time"
          text = easy_tag('time',:instance => "generated", :field => name,:value=> value, :read_only=> read_only, :bootstrap_length => false)
          span_size = 2
        when "date"
          text = easy_tag('date',:instance => "generated", :field => name,:value=> value, :read_only=> read_only, :bootstrap_length => false)
          span_size = 3
        when "date_time"
          text = easy_tag('date_time',:instance => "generated", :field => name,:value=> value, :read_only=> read_only, :bootstrap_length => false)
          span_size = 3
        when "boolean"
          text = easy_tag('check_box',:instance => "generated", :field => name,:value=> value, :read_only=> read_only)
          span_size = 1 
        when "radio_button"
          text = easy_tag('radio_button',:instance => "generated", :field => name,:value=> value, :read_only=> read_only,:labels => value_list)
        when "color"
          text = easy_tag('color',:instance => "generated", :field => name,:value=> value, :read_only=> read_only)
        when "file"
          if addon_param.blank?
            text = easy_tag('text',:instance => "generated", :field => name,:value=> value, :read_only=> true)
          else
            text = easy_tag('file',:instance => "generated", :field => name,:value=> value, :read_only=> read_only, :option_file => addon_param)
          end
        else
          text = easy_tag('text',:instance => "generated", :field => name,:value=> value, :read_only=> true)
        end
        mandatory_text = mandatory ? (easy_tag('mandatory',:label => "") + " ") : ""

        text=generate_tag(:div, generate_tag(:label, mandatory_text + description , {:class => "col-sm-3 control-label", :for => "generated_#{name}"}) + generate_tag(:div, text, {:class => "col-sm-#{span_size}"}), {:class => "form-group"})
      end
    end
    return text.html_safe
  end

end