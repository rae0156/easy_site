# encoding: UTF-8

module ApplicationHelper

  def generate_collapse(collection)
      id_rand = "accordion_" + rand(100000..999999).to_s 
      tmp_list = generate_list(collection,{:options => [:all_div],:UL => {:class => "accordion",:id=> id_rand},:LI => {:class => "accordion-group"}})
      html_text=tmp_list[0]
      num =0
      tmp_list[1..-1].each do |id|
        element = collection[0].class.find(id)
        html_element_text = generate_tag(:DIV, generate_tag(:a, "[title]", {:class=>"accordion-toggle","data-toggle"=>"collapse", "data-parent"=>"##{id_rand}", :href=>"#collapse#{id}"}), {:class=>"accordion-heading"}) + 
                            generate_tag(:DIV, generate_tag(:DIV, "[description]",{:class=>"accordion-inner"}) ,{:id=>"collapse#{id}",:class=>"accordion-body collapse #{(num==0 ? "in" : "")}"}) 
                            
        tmp_content = substitute_string(html_element_text,element)
        html_text.gsub!("[#{id}]",tmp_content)
        num+=1
      end
      return html_text    
  end

  def generate_carousel(collection)

    unless collection.blank?
      id_rand = rand(100000..999999).to_s 
      tmp_list = generate_list(collection,{:options => [:all_div],:UL => {:class => "carousel-inner"},:LI => {:class => "item"},:LI_FIRST => {:class => "active item"}})
      html_text=tmp_list[0]
      html_indicators_text=""
      num=0
      tmp_list[1..-1].each do |id_image|
        element = collection[0].class.find(id_image)
        html_element_text =  generate_tag(:IMG, "", {:src=>"[path]"}) + generate_tag(:DIV, generate_tag(:H4, "[title]") + generate_tag(:P, "[description]"),{:class=>"carousel-caption"}) 
        tmp_content = substitute_string(html_element_text,element)
        html_indicators_text += generate_tag(:LI, "", {"data-target"=> "#carousel_#{id_rand}", "data-slide-to"=> "#{num}", :class=>(num==0 ? "active": "")})
        html_text.gsub!("[#{id_image}]",tmp_content)
        num+=1
      end
      html_text = generate_tag(:OL, html_indicators_text, {:class=>"carousel-indicators"}) + html_text
      html_text += generate_tag(:A, "&lsaquo;", {:class=>"carousel-control left", :href => "#carousel_#{id_rand}", "data-slide" => "prev"}) + generate_tag(:A, "&rsaquo;", {:class=>"carousel-control right", :href => "#carousel_#{id_rand}", "data-slide" => "next"})
      
      html_text = generate_tag(:DIV, html_text, {:id=>"carousel_#{id_rand}",:class=>"carousel slide"}) + generate_tag(:script, "$('.carousel').carousel()", {:type=>"text/javascript"})
    else
      html_text=""
    end
    return html_text
  end

  def generate_blog(collection)
    tmp_list = generate_list(collection,{:options => [:container,:before_element],:DIV => {:class => "media-body"},:UL => {:class => "media-list"},:LI => {:class => "media"}})
    html_text=tmp_list[0]
    tmp_list[1..-1].each do |id_image|
      element = collection[0].class.find(id_image)
      html_element_text_before =  generate_tag(:A, generate_tag(:IMG, "", {:class=>"media-object",:src=>"[path]"}), {:class=>"pull-left"}) 
      html_element_text_container = generate_tag(:H4, "[title]", {:class=>"media-heading"}) + generate_tag(:P, "[description]") 
      tmp_content_before = substitute_string(html_element_text_before,element)
      tmp_content_container = substitute_string(html_element_text_container,element)
      
      html_text.gsub!("[BEFORE_#{id_image}]",tmp_content_before)
      html_text.gsub!("[#{id_image}]",tmp_content_container)
    end
    
    return html_text
  end

  def generate_image_list(collection)
    tmp_list = generate_list(collection,{:UL => {:class => "thumbnails"},:LI => {:class => "span2"}})
    html_text=tmp_list[0]
    
    tmp_list[1..-1].each do |id_image|
      element = collection[0].class.find(id_image)
      tmp_content = substitute_string(generate_tag(:A, generate_tag(:IMG, "", {:src=>"[path]"}) + generate_tag(:H3, "[title]") + generate_tag(:P, "[description]"), {:href=>"#", :class=>"thumbnail"}),element)
      html_text.gsub!("[#{id_image}]",tmp_content)
    end
    
    return html_text
  end

  def generate_breadcrumb(*adrs)
    html_text=""
    num=1
    adrs.each do |adr|
     
      if adr.is_a?(Array) && adr.count > 1
        tmp_elem = generate_tag(:A, adr[0], {:href=>adr[1]})
      else
        tmp_elem = adr.split.join
      end
      tmp_elem+=generate_tag(:SPAN, "", {:class=>"divider"}) if num<adrs.count
      html_text+=generate_tag(:LI, tmp_elem)
      num+=1
    end if adrs.count > 0
    html_text=generate_tag(:UL, html_text, {:class=>"breadcrumb"}) unless html_text.blank?
    
    return html_text
    
  end

  def generate_alert(msg,title='',level='')
    return generate_tag(:DIV, generate_tag(:button, "&times;",{:class=> "close",:type=>"button", "data-dismiss"=>"alert"}) + (title=='' ? "" : generate_tag(:H4,title)) + msg,{:class=> "alert #{level}"}) 
  end


  def generate_citation(citation)
    return substitute_string(generate_tag(:P, "[title]") + generate_tag(:P, generate_tag(:blockquote, "[description]<BR>" + generate_tag(:small, "[reference]",{:class => "pull-right"}))),citation) 
  end

  def generate_video(video)
    return substitute_string(generate_tag(:DIV, "<iframe width='[width]' height='[height]' src='[path]' frameborder='0' allowfullscreen></iframe>", {:class => 'flex-video widescreen'}) ,video) 
  end

  def substitute_string(text,instance=nil)
    list_word=[]
    text.split("[").each do |word|
      unless word.index("]").blank?
        list_word << word[0..word.index("]")-1]
      end
    end
    list_word.each do |word|
      tmp_word_replaced=""
      if instance.blank?
        case word.split('.').first
        when "setup"
          tmp_word_replaced=EsSetup.get_setup(word.split('.')[1..-1])
        end
      else
        tmp_word_replaced = instance.send(word) if instance.respond_to?(word) && !instance.send(word).blank?
      end
      text.gsub!("[#{word}]",tmp_word_replaced.to_s)
    end unless list_word.blank?
    return text
  end

  def generate_menu(menu_name,options={})
    element = EsMenu.find_by_name(menu_name)
    case element.link_type
    when "navigation"
        return generate_navigation(element)
    when "side"
        return generate_side(element)
    when "vertical_menu"
        return generate_vertical_menu(element)
    when "dropdown"
        return generate_dropdown(element)
    when "sheet"
        return generate_sheet(element)
    end      
  end

  def generate_sheet(element,options={})
    tmp_list = generate_list(element,{:UL_LEVEL_1 => {:class => "nav nav-tabs"},
                                      :UL_LEVEL_2 => {:class => "dropdown-menu"},
                                      :LI_HAS_CHILDREN_LEVEL_1 => {:class => 'dropdown'},
                                      :LI_FIRST => {:class => "active"}
                                      })
    html_text = tmp_list[0]
    tmp_tab_html = ""
    num=0
    tmp_list[1..-1].each do |elem|
      menu = EsMenu.find(elem)
      if menu.link_type=="separated"
        html_text.gsub!("<LI>[#{elem}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
      else
        tmp_link = generate_link(menu)
        html_text.gsub!("[#{elem}]",tmp_link)
      end
      
      if menu.link_type=="link_sheet"
        tmp_media = EsMediaFile.find_by_name(menu.link_params)
        tmp_tab_html+=generate_tag(:DIV, tmp_media.description, {:id=> "tab_#{menu.link_params}",:class => "tab-pane fade #{(num==0 ? 'in active' : '')}"}) unless tmp_media.blank?
      end
    num+=1   
    end if tmp_list.count > 1 

    html_text += generate_tag(:DIV, tmp_tab_html, {:class => "tab-content"})

    return html_text
  end

  def generate_dropdown(element,options={})
    tmp_list = generate_list(element,{:options => [:before],:UL => {:class => "dropdown-menu", :role=>"menu", "aria-labelledby"=>"dropdownMenu"},
                                      })
    html_text = tmp_list[0]

    html_text.gsub!("[BEFORE]",generate_link(element))

    tmp_list[1..-1].each do |elem|
      menu = EsMenu.find(elem)
      if menu.link_type=="separated"
        html_text.gsub!("<LI>[#{elem}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
      else
        tmp_link = generate_link(menu)
        html_text.gsub!("[#{elem}]",tmp_link)
      end
    end if tmp_list.count > 1 

    html_text=generate_tag(:DIV, html_text, {:class => "dropdown"})    
    return html_text
  end

  def generate_vertical_menu(element,options={})
    tmp_list = generate_list(element,{:UL_LEVEL_1 => {:class => "nav"},
                                      :UL_LEVEL_2 => {:class => "dropdown-menu"},
                                      :UL_LEVEL_OTHER => {:class => "dropdown-menu submenu-show submenu-hide"},
                                      :LI_HAS_CHILDREN_LEVEL_1 => {:class => 'dropdown'},
                                      :LI_HAS_CHILDREN_LEVEL_2 => {:class => 'dropdown submenu'},
                                      :LI_HAS_CHILDREN_LEVEL_OTHER => {:class => 'dropdown submenu'}
                                      })
    html_text = tmp_list[0]


    tmp_list[1..-1].each do |elem|
      menu = EsMenu.find(elem)
      if menu.link_type=="separated"
        html_text.gsub!("<LI>[#{elem}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
      else
        tmp_link = generate_link(menu)
        html_text.gsub!("[#{elem}]",tmp_link)
      end
    end if tmp_list.count > 1 

    html_text=generate_tag(:DIV, html_text, {:class => "nav-collapse"})    
    return html_text
  end

  def generate_side(element,options={})
    tmp_list = generate_list(element,{:options => [:first],:UL => {:class => "nav nav-list"}})
    html_text = tmp_list[0]
    html_text.gsub!("[FIRST]",generate_tag(:LI, element.description, {:class => "nav-header"}))

    tmp_list[1..-1].each do |elem|
      menu = EsMenu.find(elem)
      tmp_link = generate_link(menu)
      html_text.gsub!("[#{elem}]",tmp_link)
    end if tmp_list.count > 1 
    
    return html_text
  end


  def generate_navigation(element,options={})
    tmp_list = generate_list(element,{:UL => {:class => "nav"}})
    html_text = tmp_list[0]
    tmp_list[1..-1].each do |elem|
      menu = EsMenu.find(elem)
      tmp_link = generate_link(menu)
      html_text.gsub!("[#{elem}]",tmp_link)
    end if tmp_list.count > 1 
    
    return html_text
  end

  def generate_list(element,options={})
    #return a html text and elements id   
    temp_ul=""
    tab_element = []
    text_list=""
    list_type=""
    list_type = "tree" if element.respond_to?(:parent_id) && !element.children.blank?
    list_type = "array" if element.is_a?(Array) && !element.blank?
    level = options[:level]||1

    unless list_type.blank?  
      text_list += options.has_key?(:options) && options[:options].include?(:first) ? "[FIRST]" : ""
      
      case list_type
      when "tree"
        num=0
        element.children.each do |child|
          num+=1
          options[:level]=level+1
          tmp_sub_child = child.children.blank? ? [""] : generate_list(child,options)
  
          before_element = options.has_key?(:options) && options[:options].include?(:before_element) ? "[BEFORE_#{child.id}]" : ""
          after_element =  options.has_key?(:options) && options[:options].include?(:after_element) ? "[AFTER_#{child.id}]" : ""
          text_element = "[#{child.id}]" + tmp_sub_child[0]
          text_element = generate_tag(:DIV, text_element, options[:DIV]||{}) if options.has_key?(:options) && options[:options].include?(:container)
          text_element = before_element + text_element + after_element

          tmp_tag = options.has_key?(:options) && options[:options].include?(:all_div) ? :DIV : :LI
          
          unless child.children.blank?
            if level==1
              tmp_options = options[:LI_HAS_CHILDREN_LEVEL_1]||{}
            elsif level==2
              tmp_options = options[:LI_HAS_CHILDREN_LEVEL_2]||{}
            else  
              tmp_options = options[:LI_HAS_CHILDREN_LEVEL_3]||{}
            end
          end
          tmp_options = (options[:LI]||{}) if tmp_options.blank?


          tmp_options = (options[:LI_FIRST]||tmp_options) if num==1 && level==1
          
          text_list += generate_tag(tmp_tag, text_element, tmp_options)
  
          tab_element << child.id
          tab_element += tmp_sub_child[1..-1] unless tmp_sub_child.blank?
        end 
      when "array"
        num=0
        element.each do |child|
          num+=1
          options[:level]=level+1
          tmp_sub_child = child.children.blank? ? [""] : generate_list(child,options)

          before_element = options.has_key?(:options) && options[:options].include?(:before_element) ? "[BEFORE_#{child.id}]" : ""
          after_element =  options.has_key?(:options) && options[:options].include?(:after_element) ? "[AFTER_#{child.id}]" : ""
          text_element = "[#{child.id}]" + tmp_sub_child[0]
          text_element = generate_tag(:DIV, text_element, options[:DIV]||{}) if options.has_key?(:options) && options[:options].include?(:container)
          text_element = before_element + text_element + after_element

          tmp_tag = options.has_key?(:options) && options[:options].include?(:all_div) ? :DIV : :LI
          tmp_options = options[:LI]||{}
          tmp_options = (options[:LI_FIRST]||tmp_options) if num==1 
          text_list += generate_tag(tmp_tag, text_element, tmp_options)
          
          tab_element << child.id
          tab_element += tmp_sub_child[1..-1] if tmp_sub_child.count > 1
        end 
      end        
      
      text_list += options.has_key?(:options) && options[:options].include?(:last) ? "[LAST]" : ""

      tmp_tag = options.has_key?(:options) && options[:options].include?(:all_div) ? :DIV : :UL

      if level==1
        tmp_options = options[:UL_LEVEL_1]||{}
      elsif level==2
        tmp_options = options[:UL_LEVEL_2]||{}
      else  
        tmp_options = options[:UL_LEVEL_OTHER]||{}
      end
      tmp_options = (options[:UL]||{}) if tmp_options.blank?


      temp_ul= generate_tag(tmp_tag, text_list, tmp_options)
    end
    
    temp_ul = (options.has_key?(:options) && options[:options].include?(:before) ? "[BEFORE]" : "") + temp_ul + (options.has_key?(:options) && options[:options].include?(:after) ? "[AFTER]" : "")
    return [temp_ul] + tab_element
  end

  def generate_tag(tag,content,options={})
    
    options={} if options.blank? #for nil object
    tmp_options=""
    options.each do |key,value|
      tmp_options += " #{key}=" + '"' + "#{value}" + '"'
    end
    
    if ["img"].include?(tag.to_s.downcase)
      tmp_text = "<#{tag}#{tmp_options} #{content}>"
    else
      tmp_text = "<#{tag}#{tmp_options}>#{content}</#{tag}>"
    end
    
    return tmp_text
  end

  def generate_link(menu)
    tmp_link=""
    unless menu.blank?
      case menu.link_type
      when "function"
          tmp_link = link_to(menu.name, EsFonction.execute(menu.link_params))
      when "link_sheet"
          tmp_link = generate_tag("a", menu.name, {"data-toggle"=> "tab", "href"=> "#tab_#{menu.link_params}"})
      when "submenu" 
          tmp_link = generate_tag("a", menu.name + generate_tag("B","",{:class => "caret"}), {:class => "dropdown-toggle", "data-toggle"=> "dropdown", "href"=> "#"})
      when "dropdown"
          tmp_link = generate_tag("a", menu.name, {:class => "dropdown-toggle", "data-toggle"=> "dropdown", "href"=> "#"})
      end    
    end
    return tmp_link
  end














  def sort_link_remote(link_options)
    # Get the parameters from the hash
    text          = link_options[:text]
    column        = link_options[:column]
    controller    = link_options[:controller]
    action        = link_options[:action]
    extra_params  = link_options[:extra_params]
    key = column
    icon = ''
    if ((params[:sort] == column) || (params[:sort].nil?))
      key += "_reverse"
    end

    icon = "<i class='icon-arrow-up'></i>" if (params[:sort] == column)
    icon = "<i class='icon-arrow-down'></i>" if (params[:sort] == column + '_reverse')


    param_merged = params.merge({:sort => key, :id => nil, :page => nil, :controller => controller, :action => action })
    param_merged = param_merged.merge(extra_params) unless extra_params.nil?
    path = {
        :url => { :params => param_merged }
    }
    html_options = {
      :title => "Sort by #{text}",
      :href => url_for( :params => param_merged ),
      :remote => true
    }
    link_to(icon.html_safe + text, path, html_options)
  end


  def errors_for(object, message=nil)
    html = ""
    unless object.errors.blank?
      html << "<div id = 'errorExplanation' class='alert alert-error'>\n"
      if message.blank?
        if object.new_record?
          html << "<h4>#{object.errors.full_messages.length} erreur(s) pour '#{object.class.name.underscore.humanize.downcase}' </h4>"
          html << "\t\t<p>Il y a un problème lors de la création de #{object.class.name.underscore.humanize.downcase}</p>\n"
        else
          html << "<h4>#{object.errors.full_messages.length} erreur(s) pour '#{object.class.name.underscore.humanize.downcase}' </h4>"
          html << "\t\t<p>Il y a un problème lors de la modification de #{object.class.name.underscore.humanize.downcase}</p>\n"
        end    
      else
        if message == "delete"
          html << "<h4>#{object.errors.full_messages.length} erreur(s) pour '#{object.class.name.underscore.humanize.downcase}' </h4>"
          html << "\t\t<p>Il y a un problème lors de la suppression de #{object.class.name.underscore.humanize.downcase}</p>\n"
        else
          html << "<h4>#{object.errors.full_messages.length} erreur(s) pour #{message} </h4>"
          html << "<p>Détail :</p>"
        end
      end  
      html << "\t\t<ul>\n"
      object.errors.full_messages.each do |error|
        html << "\t\t\t<li>#{error}</li>\n"
      end
      html << "\t\t</ul>\n"
      html << "\t</div>\n"
    end
    html
  end  

  # Generate the description with the styles for the form fields of the new and edit screens
  def field_description(text, mandatory = false)
    ret = (mandatory ? "<span class=\"text-error\">*</span>" : "") + "<span class=\"text-error\">#{text}</span>"
    return ret.html_safe
  end
  
  
  
  
end
