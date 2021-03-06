# encoding: UTF-8

module ApplicationHelper

  include ClipboardController

  def generate_module_part(controller_name,part_name,content_detail_id)
    result = ""
    begin
      ctrl = controller_name.constantize.new
    rescue => ex
      ctrl = nil
    end    
    if ctrl.respond_to?('module_action_part')
      ctrl.params       = params
      session[:module_action_part]={:part_name => part_name,:content_id => content_detail_id}
      session[:module_action_part][:current_user]=current_user if ctrl.respond_to?('current_user=')
      response = ctrl.dispatch("module_action_part",request)
      if response.is_a?(Array) && response.size > 2 && response[2].is_a?(ActionDispatch::Response) 
        result = response[2].body
      else
        result = "Une erreur est survenue dans la génération de la partie %{part} pour le controlleur %{controller}".trn(:controller => controller_name, :part => part_name)
      end
    end
    return result.html_safe
  end

  def generate_dynamic_part(content_detail_id)
    result = ""
    content_detail = EsContentDetail.find_by_id(content_detail_id)
    if content_detail 
      result = content_detail.generate_contain_template(true)
    else
      result = "Une erreur est survenue dans la génération de la partie dynamique (numéro %{part})".trn(:part => content_detail_id)
    end
    return result.html_safe
  end

  def generate_collapse(collection)
      id_rand = "accordion_" + rand(100000..999999).to_s 
      tmp_list = generate_list(collection,{:options => [:all_div],:UL => {:class => "panel-group",:id=> id_rand},:LI => {:class => "panel panel-default"}})
      html_text=tmp_list[0]
      num =0
      tmp_list[1..-1].each do |id|
        element = collection[0].class.find(id)
        html_element_text = generate_tag(:DIV, generate_tag(:h4,generate_tag(:a, "[title]", {"data-toggle"=>"collapse", "data-parent"=>"##{id_rand}", :href=>"#collapse#{id}"}), {:class=>"panel-title"}), {:class=>"panel-heading"}) + 
                            generate_tag(:DIV, generate_tag(:DIV, "[description]",{:class=>"panel-body"}) ,{:id=>"collapse#{id}",:class=>"panel-collapse collapse #{(num==0 ? "in" : "")}"}) 
                            
        tmp_content = substitute_string(html_element_text,element,["title","description"])
        html_text.gsub!("[#{id}]",tmp_content)
        num+=1
      end
      return html_text.html_safe
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
        if !element.path.blank?
          url = ((element.path.downcase.starts_with?('http://') || element.path.downcase.starts_with?('https://')) ? '' : "http://") + element.path.to_s
          if test_url(url)
            element_html = generate_tag(:IMG, "", {:src=>url})
          else
            element_html = generate_tag(:DIV, "Le lien image '%{url}' n'est pas correcte".trn(:url => url)) 
          end
        elsif !element.reference.blank?
          if File.file?(File.join(Rails.root,element.reference))
            tmp_file = element.reference.downcase.starts_with?('public/') ? element.reference[6..-1] : element.reference
            element_html = generate_tag(:IMG, "", {:src=>tmp_file})
          else
            element_html = generate_tag(:DIV, "Le fichier image '%{url}' n'est pas correcte".trn(:url => element.reference)).html_safe 
          end
        else
          element_html = generate_tag(:DIV, "Aucune image n'est renseignée".trn) 
        end

        html_element_text =  element_html + generate_tag(:DIV, generate_tag(:H4, "[title]") + generate_tag(:P, "[description]"),{:class=>"carousel-caption"}) 

        tmp_content = substitute_string(html_element_text,element,["title","description"])
        html_indicators_text += generate_tag(:LI, "", {"data-target"=> "#carousel_#{id_rand}", "data-slide-to"=> "#{num}", :class=>(num==0 ? "active": "")})
        html_text.gsub!("[#{id_image}]",tmp_content)
        num+=1
      end
      html_text = generate_tag(:OL, html_indicators_text, {:class=>"carousel-indicators"}) + html_text
      html_text += generate_tag(:A, "<span class='glyphicon glyphicon-chevron-left'></span>", {:class=>"carousel-control left", :href => "#carousel_#{id_rand}", "data-slide" => "prev"}) + generate_tag(:A, "<span class='glyphicon glyphicon-chevron-right'></span>", {:class=>"carousel-control right", :href => "#carousel_#{id_rand}", "data-slide" => "next"})
      
      html_text = generate_tag(:DIV, html_text, {:id=>"carousel_#{id_rand}",:class=>"carousel slide"}) + generate_tag(:script, "$('.carousel').carousel()", {:type=>"text/javascript"})
    else
      html_text=""
    end
    return html_text.html_safe
  end

  def generate_blog(collection)
    tmp_list = generate_list(collection,{:options => [:container,:before_element],:DIV => {:class => "media-body"},:UL => {:class => "media-list"},:LI => {:class => "media"}})
    html_text=tmp_list[0]
    tmp_list[1..-1].each do |id_image|
      element = collection[0].class.find(id_image)


      if !element.path.blank?
        url = ((element.path.downcase.starts_with?('http://') || element.path.downcase.starts_with?('https://')) ? '' : "http://") + element.path.to_s
        if test_url(url)
          html_element_text_before = generate_tag(:A, generate_tag(:IMG, "", {:class=>"media-object",:src=>url}), {:class=>"pull-left"})
        else
          html_element_text_before = generate_tag(:DIV, "Le lien image '%{url}' n'est pas correcte".trn(:url => url)) 
        end
      elsif !element.reference.blank?
        if File.file?(File.join(Rails.root,element.reference))
          tmp_file = element.reference.downcase.starts_with?('public/') ? element.reference[6..-1] : element.reference
          html_element_text_before = generate_tag(:A, generate_tag(:IMG, "", {:class=>"media-object",:src=>tmp_file}), {:class=>"pull-left"})
        else
          html_element_text_before = generate_tag(:DIV, "Le fichier image '%{url}' n'est pas correcte".trn(:url => element.reference))
        end
      else
        html_element_text_before = generate_tag(:DIV, "Aucune image n'est renseignée".trn) 
      end


      html_element_text_container = generate_tag(:H4, "[title]", {:class=>"media-heading"}) + generate_tag(:P, "[description]") 
      tmp_content_before = substitute_string(html_element_text_before,element)
      tmp_content_container = substitute_string(html_element_text_container,element,["title","description"])
      
      html_text.gsub!("[BEFORE_#{id_image}]",tmp_content_before)
      html_text.gsub!("[#{id_image}]",tmp_content_container)
    end
    
    return html_text.html_safe
  end

  def generate_image_list(collection, options={})
    tmp_list = generate_list(collection,{:UL => {:class => "thumbnails"},:LI => {:class => "col-md-#{(options['image_size'].presence||'0').to_i * 2}"}})
    html_text=tmp_list[0]
    tmp_list[1..-1].each do |id_image|
      element = collection[0].class.find(id_image)
      
      tmp_name_descr = ""
      tmp_name_descr += generate_tag(:H3, "[title]")      if (options['name_available'].presence||'N') == 'Y'
      tmp_name_descr += generate_tag(:P, "[description]") if (options['description_available'].presence||'N') == 'Y'
      tmp_image_style = ""
      tmp_image_style += ("border: 1px solid #{(options['border_color'].presence||'black')};") if (options['border_available'].presence||'N') == 'Y'
      tmp_image_style += "background-color: #{options['background_color']};" unless (options['background_color'].presence||'').blank?

      if !element.path.blank?
        url = ((element.path.downcase.starts_with?('http://') || element.path.downcase.starts_with?('https://')) ? '' : "http://") + element.path.to_s
        if test_url(url)
          element_html = generate_tag(:IMG, "", {:src=>url})
          if (options['link_available'].presence||'N') == 'Y'
            element_html=generate_tag(:A,element_html, {:href=>url, :target => "_blank"}) 
          end
          element_html=generate_tag(:DIV,element_html + substitute_string(tmp_name_descr,element,["title","description"]), {:class=>"thumbnail", :style => tmp_image_style}) 
        else
          element_html = generate_tag(:DIV, "Le lien image '%{url}' n'est pas correcte".trn(:url => url)) 
        end
      elsif !element.reference.blank?
        if File.file?(File.join(Rails.root,element.reference))
          tmp_file = element.reference.downcase.starts_with?('public/') ? element.reference[6..-1] : element.reference
          element_html = generate_tag(:IMG, "", {:src=>tmp_file})
          if (options['link_available'].presence||'N') == 'Y'
            element_html=generate_tag(:A,element_html, {:href=>tmp_file, :target => "_blank"}) 
          end
          element_html=generate_tag(:DIV,element_html + substitute_string(tmp_name_descr,element,["title","description"]), {:class=>"thumbnail", :style => tmp_image_style}) 
        else
          element_html = generate_tag(:DIV, "Le fichier image '%{url}' n'est pas correcte".trn(:url => element.reference)).html_safe 
        end
      else
        element_html = generate_tag(:DIV, "Aucune image n'est renseignée".trn) 
      end

      tmp_content = element_html 
      html_text.gsub!("[#{id_image}]",tmp_content)
    end
    
    return (html_text + "<div style='clear:both;'></div>").html_safe
  end

  def generate_breadcrumb(*adrs)
    html_text=""
    num=1

    adrs.each do |adr|
     
      if adr.is_a?(Array) && adr.count > 1
        unless adr[1].include?('.')
          url = adr[1]
        else
          url = ((adr[1].downcase.starts_with?('http://') || adr[1].downcase.starts_with?('https://')) ? '' : "http://") + adr[1]
        end   
        tmp_elem = generate_tag(:A, adr[0], {:href=>url, "data-remote" => ((adr.count>2 && adr[2]==true) ? "true" : "false")})
      else
        tmp_elem = adr.split.join
      end
      tmp_elem+=generate_tag(:SPAN, "", {:class=>"divider"}) if num<adrs.count
      html_text+=generate_tag(:LI, tmp_elem)
      num+=1
    end if adrs.count > 0
    html_text=generate_tag(:UL, html_text, {:class=>"breadcrumb"}) unless html_text.blank?
    
    return html_text.html_safe
    
  end

  def generate_alert(msg,title='',level='')
    return generate_tag(:DIV, generate_tag(:button, "&times;",{:class=> "close",:type=>"button", "data-dismiss"=>"alert"}) + (title=='' ? "" : generate_tag(:H4,title)) + msg,{:class=> "alert #{level}"}).html_safe 
  end


  def generate_citation(citation)
    return substitute_string(generate_tag(:P, "[title]") + generate_tag(:P, generate_tag(:blockquote, "[description]<BR>" + generate_tag(:small, "[reference]",{:class => "pull-right"}))),citation,["title","description","reference"]).html_safe 
  end

  def generate_video(video)
    if video && !video.path.blank?
      url = ((video.path.downcase.starts_with?('http://') || video.path.downcase.starts_with?('https://')) ? '' : "http://") + video.path.to_s
      if test_url(url)
        return substitute_string(generate_tag(:DIV, "<iframe width='[width]' height='[height]' src='#{url}' frameborder='0' allowfullscreen></iframe>", {:class => 'flex-video widescreen'}) ,video).html_safe 
      else
        return generate_tag(:DIV, "Le lien vidéo '%{url}' n'est pas correcte".trn(:url => url)).html_safe 
      end
    elsif video && !video.reference.blank?
      if File.file?(File.join(Rails.root,video.reference))
        tmp_file = video.reference.downcase.starts_with?('public/') ? video.reference[6..-1] : video.reference
        text = "<embed src='#{tmp_file}' width='#{video.width}' height='#{video.height}'></embed>"        

        return text.html_safe 
      else
        return generate_tag(:DIV, "Le fichier vidéo '%{url}' n'est pas correcte".trn(:url => video.reference)).html_safe 
      end
    else
      return generate_tag(:DIV, "Aucune vidéo n'est renseignée".trn).html_safe 
    end
  end

  def substitute_string(text,instance=nil,fields_to_translate=[])
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
      elsif instance.respond_to?(word) && !instance.send(word).blank?
        tmp_word_replaced = instance.send(word) 
        tmp_word_replaced = tmp_word_replaced.trn if fields_to_translate.include?(word)
      end
      text.gsub!("[#{word}]",tmp_word_replaced.to_s)
    end unless list_word.blank?
    return text.html_safe
  end

  def generate_menu(menu_name,options={})
    element = EsMenu.find_by_name(menu_name)
    return "" if element.nil?  
    case element.link_type    
    when "horizontal"
        return generate_horizontal(element,options).html_safe
    when "navigation"
        return generate_navigation(element,options).html_safe
    when "side"
        return generate_side(element,options).html_safe
    when "vertical_menu"
        return generate_vertical_menu(element,options).html_safe
    when "dropdown"
        return generate_dropdown(element,options).html_safe
    when "sheet"
        return generate_sheet(element,options).html_safe
    end    
  end

  def generate_sheet(element,options={})
    tmp_list = generate_list(element,{:UL_LEVEL_1 => {:class => "nav navbar-default nav-tabs"}, #navbar-nav
                                      :UL_LEVEL_2 => {:class => "dropdown-menu"},
                                      :LI_HAS_CHILDREN_LEVEL_1 => {:class => 'dropdown'},
                                      :LI_FIRST => {:class => "active"}
                                      })
    html_text = tmp_list[0]
    tmp_tab_html = ""
    num=0

    if tmp_list.count > 1 
      tmp_array= tmp_list[1..-1]
      EsMenu.order("sequence").all.each do |menu|
        if tmp_array.include?(menu.id)
          if menu.link_type=="separated"
            html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
          else
            tmp_link = generate_link(menu)
            html_text.gsub!("[#{menu.id}]",tmp_link)
          end
          
          if menu.link_type=="link_sheet"
            tmp_media = EsMediaFile.find(:first, :conditions => {:name => menu.link_params, :media_type => "sheet"})
            tmp_tab_html+=generate_tag(:DIV, tmp_media.description, {:id=> "tab_#{menu.link_params}",:class => "tab-pane fade #{(num==0 ? 'in active' : '')}"}) unless tmp_media.blank?
          end
          num+=1   
        end
      end 
    end


#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      if menu.link_type=="separated"
#        html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
#      else
#        tmp_link = generate_link(menu)
#        html_text.gsub!("[#{menu.id}]",tmp_link)
#      end
#      
#      if menu.link_type=="link_sheet"
#        tmp_media = EsMediaFile.find(:first, :conditions => {:name => menu.link_params, :media_type => "sheet"})
#        tmp_tab_html+=generate_tag(:DIV, tmp_media.description, {:id=> "tab_#{menu.link_params}",:class => "tab-pane fade #{(num==0 ? 'in active' : '')}"}) unless tmp_media.blank?
#      end
#      num+=1   
#    end if tmp_list.count > 1 

    html_text += generate_tag(:DIV, tmp_tab_html, {:class => "tab-content"})

    return html_text
  end

  def generate_dropdown(element,options={})
    tmp_list = generate_list(element,{:options => [:before],:UL => {:class => "dropdown-menu", :role=>"menu", "aria-labelledby"=>"dropdownMenu"},
                                      })
    html_text = tmp_list[0]

    html_text.gsub!("[BEFORE]",generate_link(element))

    if tmp_list.count > 1 
      tmp_array= tmp_list[1..-1]
      EsMenu.all.each do |menu|
        if tmp_array.include?(menu.id)
          if menu.link_type=="separated"
            html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
          else
            tmp_link = generate_link(menu)
            html_text.gsub!("[#{menu.id}]",tmp_link)
          end
        end
      end 
    end

#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      if menu.link_type=="separated"
#        html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
#      else
#        tmp_link = generate_link(menu)
#        html_text.gsub!("[#{menu.id}]",tmp_link)
#      end
#    end if tmp_list.count > 1 

    html_text=generate_tag(:DIV, html_text, {:class => "dropdown"})    
    return html_text
  end

  def generate_vertical_menu(element,options={})

    class_menu,style_menu = manage_menu_options(options)

    tmp_list = generate_list(element,{:UL_LEVEL_1 => {:class => "dropdown-menu", :role=>"menu", "aria-labelledby"=>"dropdownMenu", :style => style_menu},
                                      :UL_LEVEL_2 => {:class => "dropdown-menu", :style => style_menu},
                                      :UL_LEVEL_OTHER => {:class => "dropdown-menu", :style => style_menu},
                                      :LI_HAS_CHILDREN_LEVEL_1 => {:class => 'dropdown-submenu ' + class_menu},
                                      :LI_HAS_CHILDREN_LEVEL_2 => {:class => 'dropdown-submenu ' + class_menu},
                                      :LI_HAS_CHILDREN_LEVEL_OTHER => {:class => 'dropdown-submenu ' + class_menu}
                                      })
    html_text = tmp_list[0]

    if tmp_list.count > 1 
      tmp_array= tmp_list[1..-1]
      EsMenu.all.each do |menu|
        if tmp_array.include?(menu.id)
          if menu.link_type=="separated"
            html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
          else
            tmp_link = generate_link(menu)
            html_text.gsub!("[#{menu.id}]",tmp_link)
          end
        end
      end 
    end

#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      if menu.link_type=="separated"
#        html_text.gsub!("<LI>[#{elem}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
#      else
#        tmp_link = generate_link(menu)
#        html_text.gsub!("[#{elem}]",tmp_link)
#      end
#    end if tmp_list.count > 1 

    html_text=generate_tag(:DIV, html_text, {:class => "dropdown menu " + class_menu})    
    return html_text
  end

#  def generate_vertical_menu(element,options={})
#    tmp_list = generate_list(element,{:UL_LEVEL_1 => {:class => "nav navbar-default navbar-nav"},
#                                      :UL_LEVEL_2 => {:class => "dropdown-menu"},
#                                      :UL_LEVEL_OTHER => {:class => "dropdown-menu submenu-show submenu-hide"},
#                                      :LI_HAS_CHILDREN_LEVEL_1 => {:class => 'dropdown'},
#                                      :LI_HAS_CHILDREN_LEVEL_2 => {:class => 'dropdown submenu'},
#                                      :LI_HAS_CHILDREN_LEVEL_OTHER => {:class => 'dropdown submenu'}
#                                      })
#    html_text = tmp_list[0]
#
#
#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      if menu.link_type=="separated"
#        html_text.gsub!("<LI>[#{elem}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
#      else
#        tmp_link = generate_link(menu)
#        html_text.gsub!("[#{elem}]",tmp_link)
#      end
#    end if tmp_list.count > 1 
#
#    html_text=generate_tag(:DIV, html_text, {:class => "nav-collapse"})    
#    return html_text
#  end

  def generate_side(element,options={})
    tmp_list = generate_list(element,{#:options => [:first],
                                      :UL => {:class => "nav nav-pills nav-stacked"}})
    html_text = tmp_list[0]
    #html_text.gsub!("[FIRST]",generate_tag(:LI, element.description, {:class => "nav-header"}))

    if tmp_list.count > 1 
      tmp_array= tmp_list[1..-1]
      EsMenu.all.each do |menu|
        if tmp_array.include?(menu.id)
          tmp_link = generate_link(menu)
          html_text.gsub!("[#{menu.id}]",tmp_link)
        end
      end 
    end
#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      tmp_link = generate_link(menu)
#      html_text.gsub!("[#{menu.id}]",tmp_link)
#    end if tmp_list.count > 1 

    return generate_tag(:DIV,  generate_tag(:div, element.description) + html_text)
  end


  def generate_horizontal(element,options={})

    class_menu,style_menu = manage_menu_options(options)

    tmp_list = generate_list(element,{:UL_LEVEL_1 => {:class => "nav navbar-default nav-tabs " + class_menu, :style => style_menu}, #navbar-nav
                                      :UL_LEVEL_2 => {:class => "dropdown-menu", :style => style_menu},
                                      :UL_LEVEL_OTHER => {:class => "dropdown-menu", :style => style_menu},
                                      :LI_HAS_CHILDREN_LEVEL_1 => {:class => 'dropdown ' + class_menu},
                                      :LI_HAS_CHILDREN_LEVEL_2 => {:class => 'dropdown-submenu ' + class_menu},
                                      :LI_HAS_CHILDREN_LEVEL_OTHER => {:class => 'dropdown-submenu ' + class_menu}
                                      })
    html_text = tmp_list[0]
    tmp_tab_html = ""
    num=0
    if tmp_list.count > 1 
      tmp_array= tmp_list[1..-1]
      EsMenu.order("sequence").all.each do |menu|
        if tmp_array.include?(menu.id)
          if menu.link_type=="separated"
            html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
          else
            tmp_link = generate_link(menu)
            html_text.gsub!("[#{menu.id}]",tmp_link)
          end
          
          if menu.link_type=="link_sheet"
            tmp_media = EsMediaFile.find(:first, :conditions => {:name => menu.link_params, :media_type => "sheet"})
            tmp_tab_html+=generate_tag(:DIV, tmp_media.description, {:id=> "tab_#{menu.link_params}",:class => "tab-pane fade #{(num==0 ? 'in active' : '')}"}) unless tmp_media.blank?
          end
          num+=1   
        end
      end 
    end

#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      if menu.link_type=="separated"
#        html_text.gsub!("<LI>[#{menu.id}]</LI>",generate_tag(:LI, "", {:class => "divider"}))
#      else
#        tmp_link = generate_link(menu)
#        html_text.gsub!("[#{menu.id}]",tmp_link)
#      end
#      
#      if menu.link_type=="link_sheet"
#        tmp_media = EsMediaFile.find(:first, :conditions => {:name => menu.link_params, :media_type => "sheet"})
#        tmp_tab_html+=generate_tag(:DIV, tmp_media.description, {:id=> "tab_#{menu.link_params}",:class => "tab-pane fade #{(num==0 ? 'in active' : '')}"}) unless tmp_media.blank?
#      end
#      num+=1   
#    end if tmp_list.count > 1 

    html_text += generate_tag(:DIV, tmp_tab_html, {:class => "tab-content"})

    return html_text
  end


  def generate_navigation(element,options={})
    tmp_list = generate_list(element,{:UL => {:class => "nav nav-pills"}})
    html_text = tmp_list[0]
    if tmp_list.count > 1 
      tmp_array= tmp_list[1..-1]
      EsMenu.all.each do |menu|
        if tmp_array.include?(menu.id)
          tmp_link = generate_link(menu)
          html_text.gsub!("[#{menu.id}]",tmp_link)
        end
      end 
    end
    
#    tmp_list[1..-1].each do |elem|
#      menu = EsMenu.find(elem)
#      tmp_link = generate_link(menu)
#      html_text.gsub!("[#{menu.id}]",tmp_link)
#    end if tmp_list.count > 1 
    
    return generate_tag(:div,html_text,:class => "navbar navbar-default navbar-fluid-top")
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
          if child.children.blank? 
            if child.respond_to?('all_roles') && child.all_roles == 'N' 
              next if (EsUser.current_user.blank? || !EsUser.current_user.role?(child.es_roles.collect(&:name)))
            end
          elsif tmp_sub_child == [""]
            next 
          end
  
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
              tmp_options = options[:LI_HAS_CHILDREN_LEVEL_OTHER]||{}
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
          if child.children.blank? 
            if child.respond_to?('all_roles') && child.all_roles == 'N' 
              next if (EsUser.current_user.blank? || !EsUser.current_user.role?(child.es_roles.collect(&:name)))
            end
          elsif tmp_sub_child == [""]
            next 
          end

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
      
      unless text_list.blank?
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
        
    end
    
    temp_ul = (options.has_key?(:options) && options[:options].include?(:before) ? "[BEFORE]" : "") + temp_ul + (options.has_key?(:options) && options[:options].include?(:after) ? "[AFTER]" : "")
    return [temp_ul] + tab_element
  end


  def generate_link(menu)
    tmp_link=""
    unless menu.blank?
      case menu.link_type
      when "link"
          html_options = {:title => menu.description.trn}
          if menu.link_params=="[MENU]"
            url_options = menu.controller.blank? ? '' : EsModule.get_url_from_module_menu(menu.controller)
          else
            menu_param = {}
            menu_param[:controller] = "/#{menu.controller}" unless menu.controller.blank?
            menu_param[:action]     = menu.action unless menu.action.blank?
            unless menu.link_params.blank?
              menu.link_params.split('|').each do |param_value|
                unless param_value.index('=').nil?
                  param = param_value.split('=')[0].to_sym
                  value = param_value[param_value.index('=')+1..-1]
                  menu_param[param] = value
                end 
              end
            end
            if menu_param.blank?
              url_options = "#" 
            else
              url_options = {}
              menu_param.each do |opt,val|
                if [:target, :title].include?(opt)
                  html_options[opt]=val
                else
                  url_options[opt]=val
                end
              end
              url_options = url_options[:url] if url_options[:url].presence && !url_options[:controller].present? && !url_options[:action].present? #si param url présent et pas de controller/action, alors on ne prend aue l'url
            end          
          end
          tmp_link = link_to(menu.name.trn, url_options, html_options)
      when "link_sheet"
          tmp_link = generate_tag("a", menu.name.trn, {"data-toggle"=> "tab", "href"=> "#tab_#{menu.link_params}",:title => menu.description.trn})
      when "submenu" 
          tmp_link = generate_tag("a", menu.name.trn , {:class => "dropdown-toggle", "data-toggle"=> "dropdown", "href"=> "#",:title => menu.description.trn})
#          tmp_link = generate_tag("a", menu.name + generate_tag("B","",{:class => "caret"}), {:class => "dropdown-toggle", "data-toggle"=> "dropdown", "href"=> "#"})
      when "dropdown"
          tmp_link = generate_tag("a", menu.name.trn, {:class => "dropdown-toggle", "data-toggle"=> "dropdown", "href"=> "#",:title => menu.description.trn})
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

    icon = "<i class='glyphicon glyphicon-arrow-up'></i>" if (params[:sort] == column)
    icon = "<i class='glyphicon glyphicon-arrow-down'></i>" if (params[:sort] == column + '_reverse')


    param_merged = params.merge({:sort => key, :id => nil, :page => nil, :controller => controller, :action => action })
    param_merged = param_merged.merge(extra_params) unless extra_params.nil?
    path = {
        :url => { :params => param_merged }
    }
    html_options = {
      :title => "Trié sur '%{text}'".trn(:text => text),
      :href => url_for( :params => param_merged ),
      :remote => true
    }
    link_to(icon.html_safe + text, path, html_options)
  end

  def errors_for(object, message=nil)
    if object.class.respond_to?('setup_model') && object.class.setup_model.is_a?(Hash) && !object.class.setup_model[:instance_name].presence.blank?
      tmp_model_name = object.class.setup_model[:instance_name].presence
    else
      tmp_model_name = object.class.name.underscore.humanize.downcase
      tmp_model_name = tmp_model_name.split(' ')[1..-1].join(' ') if tmp_model_name.split(' ')[0]=='es'
    end
    
    model_name = tmp_model_name.trn
    html = ""
    unless object.errors.blank?
      html << "<div id = 'errorExplanation' class='alert alert-danger'>\n"
      html << "<button data-dismiss='alert' class='close' type='button'><span aria-hidden='true'>×</span></button>\n"
      if message.blank?
        if object.new_record?
          html << "<h4>" + "%{nbr_error} erreur(s) pour '%{model_name}'".trn(:nbr_error => object.errors.full_messages.length, :model_name => model_name) + " </h4>"
          html << "\t\t<p>" + "Il y a un problème lors de la création".trn + "</p>\n"
        else
          html << "<h4>" + "%{nbr_error} erreur(s) pour '%{model_name}'".trn(:nbr_error => object.errors.full_messages.length, :model_name => model_name) + " </h4>"
          html << "\t\t<p>" + "Il y a un problème lors de la modification".trn + "</p>\n"
        end    
      elsif message == "delete"
        html << "<h4>" + "%{nbr_error} erreur(s) pour '%{model_name}'".trn(:nbr_error => object.errors.full_messages.length, :model_name => model_name) + " </h4>"
        html << "\t\t<p>" + "Il y a un problème lors de la suppression".trn + "</p>\n"
      elsif message == "[NO_MESSAGE]"
        html << "<h4>" + "%{nbr_error} erreur(s) :".trn(:nbr_error => object.errors.full_messages.length, :message => message) + " </h4>"
      else
        html << "<h4>" + "%{nbr_error} erreur(s) %{message}".trn(:nbr_error => object.errors.full_messages.length, :message => message) + " </h4>"
        html << "<p>" + "Détail".trn + " :</p>"
      end  
      html << "\t\t<ul>\n"
#      object.errors.full_messages.each do |error|
      object.errors.map do |attribute, message| 
        if message[0]== '#'
          html << "\t\t\t<li>#{message[1..-1]}</li>\n"
        else
          html << "\t\t\t<li>#{object.errors.full_message(attribute, message)}</li>\n"
        end 
      end
      html << "\t\t</ul>\n"
      html << "\t</div>\n"
    end
    html.html_safe
  end  

  # Generate the description with the styles for the form fields of the new and edit screens
  def field_description(text, mandatory = false, bootstrap = false)
    ret = (mandatory ? "<span class=\"text-danger\">*</span>" : "") + "<span class=\"text-danger\">#{text}</span>"
    ret = "<div class='col-sm-1'>#{ret}</div>" if bootstrap
    return ret.html_safe
  end
  
  
  def generate_activation_code(size = 6)
    charset = %w{ 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z}
    (0...size).map{ charset.to_a[rand(charset.size)] }.join
  end

  def page_entries_info(collection, options = {})
    entry_name = options[:model] || (collection.empty?? 'item' : collection.first.class.name.split('::').last.titleize).trn
    if collection.total_pages < 2
      case collection.size
      when 0
        "Il n'y a pas de %{element_paginate}".trn(:element_paginate => entry_name)
      else
        "Totalité des %{element_paginate}".trn(:element_paginate => entry_name.pluralize)
      end
    else
      "Affichage %{de} - %{vers} sur %{total} %{element_paginate}".trn(:de => collection.offset + 1, :vers => collection.offset + collection.length, :total => collection.total_entries, :element_paginate =>entry_name.pluralize)
    end
  
  end

private
  #detecter les class et les styles
  def manage_menu_options(options)
    class_menu = (options['menu']||[]).join(' ')

    tmp_style_menu = []
    style = (options['menu[option]']||{})
    case style["menugradient"].presence
      when "linear_top"
        tmp_style_menu << "background: linear-gradient( to top, #{style["menugradientcolorfrom"].presence||"#000"}, #{style["menugradientcolorto"].presence||"#FFF"})"
      when "linear_right"
        tmp_style_menu << "background: linear-gradient( to right, #{style["menugradientcolorfrom"].presence||"#000"}, #{style["menugradientcolorto"].presence||"#FFF"})"
      when "linear_top_right"
        tmp_style_menu << "background: linear-gradient( to top right, #{style["menugradientcolorfrom"].presence||"#000"}, #{style["menugradientcolorto"].presence||"#FFF"})"
      when "radial_ellipse"
        tmp_style_menu << "background: radial-gradient( ellipse at top left, #{style["menugradientcolorfrom"].presence||"#000"}, #{style["menugradientcolorto"].presence||"#FFF"})"
      when "radial_closest"
        tmp_style_menu << "background: radial-gradient( closest-corner at center, #{style["menugradientcolorfrom"].presence||"#000"}, #{style["menugradientcolorto"].presence||"#FFF"})"
      when "opacity"
        tmp_style_menu << "background-color: #{color_hex_to_rgba(style["menugradientcolorfrom"].presence||"#000",0.85)}"        
      when "color"
        tmp_style_menu << "background-color: #{style["menugradientcolorfrom"].presence||"#000"}"
    end
    
    tmp_style_menu << "border-width: #{style["menubordersize"].presence}px" if style["menubordersize"].present? 
    tmp_style_menu << "border-color: #{style["menubordercolor"].presence}" if style["menubordercolor"].present? 
    
    style_menu = tmp_style_menu.join(';')
    
    return class_menu, style_menu
  end


end
