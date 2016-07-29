# encoding: UTF-8

module TemplateGenerateHelper
  
  def generate_design_wizard(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      parts_containt = get_template_parts(template,template_name)
      text = generate_lines(template,0,{:empty => false,:drag_drop => true, :parts_containt => parts_containt, :wizard => true})
      return render(:inline => text.html_safe)
    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end

  end
  
  def generate_design_with_part(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      text = generate_lines(template,0,{:empty => false,:drag_drop => true})
      return text.html_safe    
    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end
  end


  def generate_design_empty(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      text = generate_lines(template,0,{:empty => true,:drag_drop => true})
      return text.html_safe
    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end
  end

  
  def generate_template_render(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      parts_containt = get_template_parts(template,template_name)
      text = generate_lines(template,0,{:empty => false,:drag_drop => false, :parts_containt => parts_containt})
      return generate_anchor('top') + render(:inline => text.html_safe)
    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end
  end

  def get_template_parts(template,template_name)
    
    parts_containt = {}
    template.es_parts.each do |p|
      unless p.es_template_col_id == 0
        if template_name==Rails.application.config.current_template
          parts_containt[p.name] = generate_anchor(p.name) + get_template_part(p.name)
        else
          parts_containt[p.name] = generate_anchor(p.name) + get_template_part(p.name,"parts",false,template_name)
        end             
      end
    end
    return parts_containt
  end

  def generate_design_part_available(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      parts = EsPart.all(:conditions => {:es_template_id => template.id})
      
      text = generate_tag(:p, "Partie(s) non placée(s) dans le template".trn)
      parts.each_with_index do |p,i|
        if (p.es_template_col_id.blank? || p.es_template_col_id == 0)
          text_col   = generate_tag(:div, generate_tag(:span, p.name, :style => "display:none;"), {:class => "label label-info label-info-hiden", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                       generate_tag(:div, p.description)
          text_col   = generate_tag(:div, text_col, {:id => "template_part_#{p.id}",:style => "position:relative;"})
          text       += text_col
        end 
      end 
      text = generate_tag(:div, text, {:class => "col-md-12",:style => "border:1px solid red;padding:5px;"})
      text = generate_tag(:div, text, {:class => "row drag_drop_template"})      
    else
      text = ""
    end
    return text.html_safe
  end
  
private

  def generate_lines(template, parent_id,options={})
    wizard         = options[:wizard].presence
    wizard         = false if wizard.nil?
    empty          = options[:empty].presence
    empty          = false if empty.nil?
    dr_dr          = options[:drag_drop].presence
    dr_dr          = false if dr_dr.nil?
    parts_containt = options[:parts_containt].presence||{}
    
    if wizard
      btns  =     link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-camera").html_safe, 
                          url_for(:controller => "es_templates" , :action => "preview_template", :id => template.id),
                          :title =>"Prévisualiser tout le template".trn,
                          :remote => true
                         ) + " " +
                  link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-share-alt").html_safe, 
                          url_for(:controller => "es_templates" , :action => "not_preview_template", :id => template.id),
                          :title =>"Sortir du mode 'Prévisualisation' pour tout le template".trn,
                          :remote => true
                         )

      text = generate_tag(:div, "Template '%{name}'".trn(:name => template.name) + " " + btns)
    else
      text = ""
    end

    tmp_lines = EsTemplateLine.all(:conditions => {:es_template_id => template.id, :es_col_parent_id => parent_id}, :order => "num")  
    tmp_lines.each_with_index do |l,y|
      text_line = ""
      l.es_template_cols.each_with_index do |c,x|
        if dr_dr
          text_col = c.description.blank? ? "ligne %{line} colonne %{col}".trn(:line => y + 1, :col => x + 1) : c.description.limit(30)
          btns = ""
          if wizard
            btns  =     link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-font").html_safe, 
                                url_for(:controller => "es_templates" , :action => "add_free_elem", :id => c.id),
                                :title =>"Ajouter un élément libre".trn,
                                :confirm =>"Voulez vous vraiment ajouter un élément libre ?".trn,
                                :remote => true
                               ) + " " +
                        link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-list-alt").html_safe, 
                                url_for(:controller => "es_templates" , :action => "add_module_elem", :id => c.id),
                                :title =>"Ajouter un élément de module".trn,
                                :remote => true
                               ) + " " +
                        link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-th-list").html_safe, 
                                url_for(:controller => "es_templates" , :action => "add_dynamic_elem", :id => c.id),
                                :title =>"Ajouter un élément dynamique".trn,
                                :confirm =>"Voulez vous vraiment ajouter un élément dynamique ?".trn,
                                :remote => true
                               ) + " " +
                        link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-file").html_safe, 
                                url_for(:controller => "es_templates" , :action => "add_part_file_elem", :id => c.id),
                                :title =>"Ajouter un élément du système".trn,
                                :remote => true
                               ) + " " +
                        link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-camera").html_safe, 
                                url_for(:controller => "es_templates" , :action => "preview_column", :id => c.id),
                                :title =>"Prévisualiser l'ensemble de '%{part}'".trn(:part => text_col),
                                :remote => true
                               ) + " " +
                        link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-share-alt").html_safe, 
                                url_for(:controller => "es_templates" , :action => "not_preview_column", :id => c.id),
                                :title =>"Sortir du mode 'Prévisualisation' pour '%{part}'".trn(:part => text_col),
                                :remote => true
                               )
          end
          text_col = generate_tag(:p, text_col + " " + btns,{:style =>"overflow:hidden;white-space:normal;"})
        else
          text_col = ""
        end
        unless empty
          c.es_parts.order('num').each do |p|
            if dr_dr && (!session[:parts_preview].present? || !session[:parts_preview].include?(p.id))
              btns = ""
              if wizard
                btns = ""
                btns  +=    link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-share").html_safe, 
                                    url_for(:controller => "es_templates" , :action => "delete_part", :id => p.id, :sub_action => "detach"),
                                    :title =>"Détacher cette partie".trn,
                                    :confirm =>"Voulez vous vraiment détacher cette partie ?".trn,
                                    :remote => true
                                   ) + " " 
                unless p.name=="part_dynamic"
                  btns  +=    link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-remove").html_safe, 
                                      url_for(:controller => "es_templates" , :action => "delete_part", :id => p.id, :sub_action => "destroy"),
                                      :title =>"Supprimer cette partie".trn,
                                      :confirm =>"Voulez vous vraiment supprimer cette partie ?".trn,
                                      :remote => true
                                     ) + " "
                end
                btns  +=    link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-camera").html_safe, 
                                    url_for(:controller => "es_templates" , :action => "preview_part", :id => p.id),
                                    :title =>"Prévisualiser cette partie".trn,
                                    :remote => true
                                   ) + " " +
                            link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-pencil").html_safe, 
                                    url_for(:controller => "es_templates" , :action => "rename_part", :id => p.id),
                                    :title =>"Renommer cette partie".trn,
                                    :remote => true
                                   ) + " "
                if p.is_dynamic
                  btns  +=    link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-edit").html_safe, 
                                      url_for(:controller => "es_templates" , :action => "edit_part", :id => p.id),
                                      :title =>"Modifier cette partie".trn,
                                      :remote => true
                                     )
                end
              end
              text_part = generate_tag(:div, generate_tag(:span, p.name + " " + btns, :style => "display:none;"), {:class => "label label-info label-info-hiden", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                          generate_tag(:div, p.description)
                          
              text_part = generate_tag(:div, text_part, {:id => "template_part_#{p.id}",:style => "position:relative;"})
            else
              if wizard
                btns  =     link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-share-alt").html_safe, 
                                    url_for(:controller => "es_templates" , :action => "not_preview_part", :id => p.id),
                                    :title =>"Travailler avec cette partie".trn,
                                    :remote => true
                                   ) 
                text_part = generate_tag(:span, generate_tag(:span, p.name + " " + btns, :style => "display:none;"), {:class => "label label-info label-info-hiden", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                            generate_tag(:div, (parts_containt[p.name].presence || ""))
                            
                text_part = generate_tag(:div, text_part, {:id => "template_part_#{p.id}",:style => "position:relative;"}) #,:class => "no_drag_drop"

              else
                text_part = parts_containt[p.name].presence || ""
              end
            end
            text_col += text_part            
          end
        end
        tmp_style = dr_dr ? "border:1px solid red;padding:5px;" : ""
        properties = EsContent.prepare_properties(c,nil,{:class => "col-md-#{c.width}",:style => tmp_style})
        text_line += generate_tag(:div, text_col, properties)
      end 
      tmp_class = dr_dr ? "row drag_drop_template" : "row"      
      properties = EsContent.prepare_properties(l,nil,{:class => tmp_class})
      text += generate_tag(:div, text_line, properties)      
    end
    text = generate_tag(:div, text, {:class => (template.template_type=='TEMPLATE' ? "container" : '')}) unless dr_dr
    return text
  end
    
end