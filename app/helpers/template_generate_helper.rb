# encoding: UTF-8

module TemplateGenerateHelper
   
  def generate_design_wizard(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      if EsTemplate.is_dynamic(template_name)
        parts_containt = get_template_parts(template,template_name)
        text = generate_lines(template,0,{:empty => false,:drag_drop => true, :parts_containt => parts_containt, :wizard => true})
        return render(:inline => text.html_safe)
      else
        session[:template_file_wizard_mode]=template_name
        text = render("templates/#{template_name}")
        session.delete(:template_file_wizard_mode)

        return render(:inline => text.html_safe)
      end

    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end

  end
  
  def get_template_file_part(part_name)

    unless session[:template_file_wizard_mode].presence
      parts_containt, num_line = nil,0
      template_name = get_caller_template
      template_name = Rails.application.config.current_template if template_name.blank?
      template = EsTemplate.find_by_name(template_name)
      if template
        tmp_col = EsTemplateCol.includes(:es_template_line => :es_template).where(["es_templates.id = ? and es_template_cols.description = ?",template.id,part_name]).first
        if tmp_col
          parts_containt = get_template_parts(template,template_name,tmp_col.id)
          num_line = tmp_col.es_template_line_id
        end 

#        part = template.es_parts.find_by_name(part_name)
#        if part && part.es_template_col
#          num_line = part.es_template_col.es_template_line ? part.es_template_col.es_template_line_id : 0
#          parts_containt = get_template_parts(template,template_name,part.es_template_col_id) 
#        end 
      end

      if parts_containt.nil?
        return get_template_part(part_name)
      else
        text = generate_lines(template,0,{:template_dyn => false, :line_ids => [num_line], :empty => false,:drag_drop => false, :parts_containt => parts_containt, :wizard => false})
        return render(:inline => text)
      end
    else
      template_name = session[:template_file_wizard_mode]
      template = EsTemplate.find_by_name(template_name)
      if template

        tmp_col = EsTemplateCol.includes(:es_template_line => :es_template).where(["es_templates.id = ? and es_template_cols.description = ?",template.id,part_name]).first

        if tmp_col
          parts_containt = get_template_parts(template,template_name,tmp_col.id)
          num_line = tmp_col.es_template_line_id
          text = generate_lines(template,0,{:template_dyn => false, :line_ids => [num_line], :empty => false,:drag_drop => true, :parts_containt => parts_containt, :wizard => true})
          return text.html_safe

#        part = template.es_parts.find_by_name(part_name)
#        if part
#          parts_containt = part.es_template_col ? get_template_parts(template,template_name,part.es_template_col_id) : {}
#          num_line = (part.es_template_col && !part.es_template_col.es_template_line_id.blank?) ? part.es_template_col.es_template_line_id : 0
#          #{part_name => get_template_part(part_name)}
#          text = generate_lines(template,0,{:line_ids => [num_line], :empty => false,:drag_drop => true, :parts_containt => parts_containt, :wizard => true})
#          return ("<P>#{part_name} #{part.id} #{part.es_template_col_id} #{part.es_template_col.description} #{num_line}</P> <BR>" + text).html_safe
        else
          return get_template_part(part_name)
        end
      else
        return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
      end
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
      if EsTemplate.is_dynamic(template_name)
        text = generate_lines(template,0,{:empty => true,:drag_drop => true})
        return text.html_safe
      else
        return render(:inline => "<p>" + "Le template %{name} est de type fichier".trn(:name=> template_name) +"</p>")
      end
    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end
  end

  def load_templates_only(template_files_to_load) # array de string => ["templates/_admin.html.erb",...]
      template_files_to_load.each do |tmp_file|
        render(:partial=> tmp_file.gsub('/_','/'))
      end
      ""
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

  def get_template_parts(template,template_name,col_id=nil)
    parts_containt = {}
    template.es_parts.each do |p|
      if p.es_template_col_id != 0 && (col_id.nil? || col_id == p.es_template_col_id)
        if template_name==Rails.application.config.current_template
          tmp_containt = get_template_part(p.name)
        else
          tmp_containt = get_template_part(p.name,"parts",false,template_name)
        end             
        
        if tmp_containt.blank?
          parts_containt[p.name] = tmp_containt
        else
          parts_containt[p.name] = generate_anchor(p.name) + tmp_containt          
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
    line_ids       = options[:line_ids].presence||[]
    template_dyn   = options[:template_dyn].nil? ? true : options[:template_dyn] 
    
    if wizard && line_ids.empty?
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
      next if !line_ids.empty? && !line_ids.include?(l.id)
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
                if p.is_dynamic && p.content_type!="system"
                  btns  +=    link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-edit").html_safe, 
                                      url_for(:controller => "es_templates" , :action => "edit_part", :id => p.id),
                                      :title =>"Modifier cette partie".trn,
                                      :remote => true
                                     ) + " "
                else
                  btns  +=    generate_tag(:i, "", :class=>"glyphicon glyphicon-edit",:title =>"Cette partie ne peut pas être modifiée".trn).html_safe + " "
                end
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
              end
              text_part = generate_tag(:div, generate_tag(:span,"&nbsp;&nbsp;" + btns + " " + p.name, :style => "display:none;"), {:class => "label label-info label-info-hiden", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                          generate_tag(:div, p.description)
                          
              text_part = generate_tag(:div, text_part, {:id => "template_part_#{p.id}",:style => "position:relative;"})
            else
              if wizard
                btns = ""
                if p.is_dynamic && p.content_type!="system"
                  btns  +=    link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-edit").html_safe, 
                                      url_for(:controller => "es_templates" , :action => "edit_part", :id => p.id),
                                      :title =>"Modifier cette partie".trn,
                                      :remote => true
                                     ) + " "
                else
                  btns  +=    generate_tag(:i, "", :class=>"glyphicon glyphicon-edit",:title =>"Cette partie ne peut pas être modifiée".trn).html_safe + " "
                end
                btns  +=     link_to(generate_tag(:i, "", :class=>"glyphicon glyphicon-share-alt").html_safe, 
                                    url_for(:controller => "es_templates" , :action => "not_preview_part", :id => p.id),
                                    :title =>"Travailler avec cette partie".trn,
                                    :remote => true
                                   ) + " "
                
                tmp_containt = (parts_containt[p.name].presence || "")
                tmp_containt = "La partie dynamique se trouve ici ...".trn if tmp_containt.blank? && p.name=="part_dynamic"
                
                tmp_style = dr_dr ? "border: 1px solid #dddddd;" : ""                
                text_part = generate_tag(:span, generate_tag(:span,"&nbsp;&nbsp;" + btns + " " + p.name, :style => "display:none;"), {:class => "label label-info label-info-hiden", :style => "position:absolute;top:-5px;left:-5px;"}) + \
                            generate_tag(:div, tmp_containt,{:style => tmp_style})
                            
                text_part = generate_tag(:div, text_part, {:id => "template_part_#{p.id}",:style => "position:relative;"}) #,:class => "no_drag_drop"

              else
                text_part = parts_containt[p.name].presence || ""
              end
            end
            text_col += text_part            
          end
        end
        tmp_style = dr_dr ? "border:1px solid red;padding:5px;" : ""
        tmp_class_col = template_dyn ? "col-md-#{c.width}" : ""
        properties = EsContent.prepare_properties(c,nil,{:class => tmp_class_col,:style => tmp_style, :col_id => c.id})
        text_line += generate_tag(:div, text_col, properties)
      end 
      tmp_class_line  = dr_dr ? "drag_drop_template" : ""  
      tmp_class_line += " row" if template_dyn    
      properties = EsContent.prepare_properties(l,nil,{:class => tmp_class_line})
      text += generate_tag(:div, text_line, properties)      
    end
    tmp_class_container = template.template_type=='TEMPLATE' && template_dyn  ? "container-fluid" : ''
    text = generate_tag(:div, text, {:class => tmp_class_container}) unless dr_dr
    return text
  end
    
end