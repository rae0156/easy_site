# encoding: UTF-8

module EasyHelper
    ACTION = {
              :label            => ["label","for","-Options html","class","style"], 
              :text             => ["instance","field","id","value","-Options html","class","style","read_only","maxlength","size","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"],
              :long_text        => ["instance","field","id","value","cols","rows","-Options html","class","style","read_only","maxlength","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"],
              :check_box        => ["instance","field","id","value","checked_value","unchecked_value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :list             => ["instance","field","id","value_list_array","selected_value","-Options visuelles","include_blank","number_of_line","multiple","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"],
              :list_collection  => ["instance","field","id","collection","value_method","text_method","selected_value","-Options visuelles","include_blank","number_of_line","multiple","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"],
              :radio_button     => ["instance","field","id","labels","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"],
              :mandatory        => ["label","-Options html","class","style"], 
              :integer          => ["--Ne pas oublier le javascript 'init_inputmask();'","instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :decimal          => ["--Ne pas oublier le javascript 'init_inputmask();'","instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :date             => ["--Ne pas oublier le javascript 'init_datepicker();'","instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","bootstrap_length","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :time             => ["--Ne pas oublier le javascript 'init_datepicker();'","instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","bootstrap_length","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :date_time        => ["--Ne pas oublier le javascript 'init_datepicker();'","instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","bootstrap_length","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :link             => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :file             => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options pour fichier","option_file","directory","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :font             => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","bootstrap_length","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :color            => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","bootstrap_length","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :text_only        => ["value","-Options html","class","style","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options additionnelles","with_label"], 
              :image            => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options pour fichier","directory","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :css              => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options pour fichier","directory","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :directory        => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options pour fichier","directory","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :sound            => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options pour fichier","directory","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :video            => ["instance","field","id","value","-Options html","class","style","read_only","-Options Bootstrap","help_text","bootstrap","bootstrap_form","-Options pour fichier","directory","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :hidden           => ["instance","field","id","value","-Options html","class"]
              }
    OPTIONS = {
                :help               => {:mandatory => false , :html_option => false, :description => "true = pour avoir l'aide en plus de la génération"}, 
                :label              => {:mandatory => true  , :html_option => false, :description => "Libellé"}, 
                :labels             => {:mandatory => true  , :html_option => false, :description => "Libellé ou liste de libellés"}, 
                :for                => {:mandatory => false , :html_option => false, :description => "Liaison avec un champs (instance_champs)"}, 
                :id                 => {:mandatory => false , :html_option => true,  :description => "Remplace l'instance et le champs"}, 
                :instance           => {:mandatory => true  , :html_option => false, :description => "Nom de l'instance"}, 
                :field              => {:mandatory => true  , :html_option => false, :description => "Nom du champs"}, 
                :value              => {:mandatory => false , :html_option => true , :description => "Valeur"}, 
                :selected_value     => {:mandatory => false , :html_option => false, :description => "Valeur"}, 
                :value_list_array   => {:mandatory => true  , :html_option => false, :description => "Liste de valeurs sous forme de tableau"},
                :collection         => {:mandatory => true  , :html_option => false, :description => "Collection"},
                :value_method       => {:mandatory => true  , :html_option => false, :description => "Méthode utilisée pour retourner les valeurs"},
                :text_method        => {:mandatory => true  , :html_option => false, :description => "Méthode utilisée pour retourner les textes"},
                :include_blank      => {:mandatory => false , :html_option => false, :description => "true = ajouter une valeur blanche", :default_value => true},
                :class              => {:mandatory => false , :html_option => true , :description => "Liste des classes"}, 
                :style              => {:mandatory => false , :html_option => true , :description => "Liste des styles CSS"}, 
                :read_only          => {:mandatory => false , :html_option => false, :description => "true = lecture seule", :default_value => false}, 
                :number_of_line     => {:mandatory => false , :html_option => false, :description => "Nombre de lignes à afficher", :default_value => 1},
                :multiple           => {:mandatory => false , :html_option => true , :description => "Sélection multiple", :default_value => false},
                :ajax_action        => {:mandatory => false , :html_option => true , :description => "Action associé à ajax (Ne pas oublier le javascript 'initajaxplus();')"},
                :mandatory          => {:mandatory => false , :html_option => false, :description => "true = ajout de l'étoile rouge", :default_value => false},
                :checked_value      => {:mandatory => false , :html_option => false, :description => "Valeur quand coché", :default_value => "Y"},
                :unchecked_value    => {:mandatory => false , :html_option => false, :description => "Valeur quand pas coché", :default_value => "N"},
                :cols               => {:mandatory => false , :html_option => true , :description => "Nombre de colonnes (Ne marche pas avec Bootstrap)", :default_value => 40}, 
                :rows               => {:mandatory => false , :html_option => true , :description => "Nombre de lignes", :default_value => 5}, 
                :maxlength          => {:mandatory => false , :html_option => true , :description => "Nombre de caractères maximum", :default_value => 60},
                :bootstrap          => {:mandatory => false , :html_option => false, :description => "Activer les classes boostrap", :default_value => true}, 
                :bootstrap_length   => {:mandatory => false , :html_option => false, :description => "Activer la longueur pour Boostrap", :default_value => true},
                :bootstrap_form     => {:mandatory => false , :html_option => false, :description => "Utiliser les formulaires Bootstrap<BR>Cette option active aussi les options 'bootstrap' et 'bootstrap_length'", :default_value => false},
                :with_label         => {:mandatory => false , :html_option => false, :description => "Ajoute un libellé"},
                :directory          => {:mandatory => false , :html_option => false, :description => "Répertoire de départ"},
                :help_text          => {:mandatory => false , :html_option => false, :description => "Affichage d'une annotation pour aider l'utilisateur"},
                :size               => {:mandatory => false , :html_option => false, :description => "Longueur d'affichage d'un texte"},
                :option_file        => {:mandatory => false , :html_option => false, :description => "Options du javascript 'filepicker.js' :<BR>Liste de 4 éléments séparés par des ';'.<BR>1) Répertoire du serveur<BR>2) Controlleur et action à exécuter<BR>3) Liste des extentions<BR>4) Autres options "}
              }
              
    def easy_tag(method="", options = {})
      if method.blank? || options.blank?
        return help(method).html_safe
      else  
        generate_tag = gererate_easy_tag(method,options)
        generate_tag += help(method,options).html_safe if options[:help].presence == true 
        return generate_tag.html_safe
      end
    end
    alias_method :help_tag, :easy_tag              
    alias_method :tag_help, :easy_tag              
    
    
private

    def gererate_easy_tag(method,options)
      field_options={}
      html_options=get_html_options(method, options)

      field_mandatory = (options[:mandatory].presence || false) ? "<span class=\"text-error\">*</span>&nbsp;".html_safe : ""
      tmp_label       = options[:with_label].present? ? options[:with_label] : ""
      bootstrap_form = options[:bootstrap_form].nil? ? false : options[:bootstrap_form] 
      if bootstrap_form
        bootstrap         = true 
        bootstrap_length  = true 
      else
        bootstrap = options[:bootstrap].nil? ? true : options[:bootstrap] 
        bootstrap_length = options[:bootstrap_length].nil? ? true : options[:bootstrap_length] 
      end

      html_options[:class]             = "" unless html_options[:class].present?
      html_options[:class]            += (bootstrap ? " form-control" : "") unless ["text_only","radio_button"].include?(method) 
      html_options[:name]  = html_options[:id] if html_options[:id].present?

      field_result = ""
      case method
      when "label"
        field_result = label_tag(options[:for].presence || "", options[:label].presence,html_options )
      when "mandatory"
        field_result = "<span class=\"text-error\">*</span><span class=\"text-error\">#{options[:label].presence}</span>".html_safe
      when "text"
        html_options[:readonly]=options[:read_only].presence||false
        html_options[:size]= options[:size] unless options[:size].presence.blank?
        #cette option 'disabled' ne renvoie rien dans le formulaire
        #html_options[:disabled]=((options[:read_only].presence||false) ? "disabled" : false)    
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options )
      when "integer"
        html_options[:readonly]=options[:read_only].presence||false
        html_options[:class]            += " inputmask"
        html_options["data-inputmask"]   = "'alias': 'integer'"
        field_result = "<div class='input-group #{bootstrap_length ? 'col-md-6' : ''}'>".html_safe +
                         text_field(options[:instance].presence, options[:field].presence,html_options) +
                       "</div>".html_safe
      when "decimal"
        html_options[:readonly]=options[:read_only].presence||false
        html_options[:class]            += " inputmask"
        #html_options["data-inputmask"]   = "'alias': 'decimal', 'groupSeparator': ',', 'autoGroup': true"
        html_options["data-inputmask"]   = "'alias': 'decimal'"
        field_result = "<div class='input-group #{bootstrap_length ? 'col-md-7' : ''}'>".html_safe +
                         text_field(options[:instance].presence, options[:field].presence,html_options) +
                       "</div>".html_safe
      when "date_time"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = "<div class='input-group date #{bootstrap_length ? 'col-md-4' : ''}' data-behaviour='datetimepicker' data-date='#{options[:value].presence}'>".html_safe +
                       text_field(options[:instance].presence, options[:field].presence,html_options) +
                       ((html_options[:readonly]==true ? "" : "<span class='input-group-addon'><i class='glyphicon glyphicon-th'></i></span>") + "</div>").html_safe
      when "date"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = "<div class='input-group date #{bootstrap_length ? 'col-md-3' : ''}' data-behaviour='datepicker' data-date='#{options[:value].presence}'>".html_safe +
                       text_field(options[:instance].presence, options[:field].presence,html_options) +
                       ((html_options[:readonly]==true ? "" : "<span class='input-group-addon'><i class='glyphicon glyphicon-th'></i></span>") + "</div>").html_safe
      when "time"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = "<div class='input-group date #{bootstrap_length ? 'col-md-3' : ''}' data-behaviour='timepicker' data-date='#{options[:value].presence}'>".html_safe +
                       text_field(options[:instance].presence, options[:field].presence,html_options) +
                       ((html_options[:readonly]==true ? "" : "<span class='input-group-addon'><i class='glyphicon glyphicon-th'></i></span>") + "</div>").html_safe
      when "long_text"
        html_options[:disabled]=((options[:read_only].presence||false) ? "disabled" : false)        
        field_result = text_area(options[:instance].presence, options[:field].presence,html_options )
      when "list", "list_collection"
        html_options[:disabled]=((options[:read_only].presence||false) ? "disabled" : false)
        html_options[:size]= options[:number_of_line] || 1
        unless options[:include_blank] == false
          field_options[:include_blank] = options[:include_blank].nil? ? true : options[:include_blank] 
        end
        field_options[:selected] = options[:selected_value] if options[:selected_value].present?
        if method== "list"
          field_result = select(options[:instance].presence, options[:field].presence, options[:value_list_array].presence||[], 
                        field_options,
                        html_options
                        )
        elsif method== "list_collection"
          field_result = collection_select(options[:instance].presence, options[:field].presence, options[:collection].presence||[], options[:value_method], options[:text_method], 
                        field_options,
                        html_options
                        )
        end
      when "link"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options )
        field_result +=  link_to("Tester le lien".trn, '#',  :target=>"_blank", :class => "control-label col-sm-12 linkpicker", :style => "text-align:left;", :rel => "#{options[:instance].presence}_#{options[:field].presence}")
      when "hidden"
        field_result = hidden_field(options[:instance].presence, options[:field].presence, html_options)
      when "check_box"
        html_options[:disabled]=options[:read_only].presence||false
        html_options[:checked] = "checked" if options[:value]==(options[:checked_value]||"Y")
        field_result = "<span class='#{bootstrap_length ? 'col-md-1' : ''}'>".html_safe +
                         check_box(options[:instance].presence, options[:field].presence,html_options, options[:checked_value]||"Y", options[:unchecked_value]||"N") +
                       "</span>".html_safe
      when "radio_button"
        html_options[:disabled]=options[:read_only].presence||false
        field_result="".html_safe
        options[:labels] = [] if options[:labels].blank?
        options[:labels] = [options[:labels]] unless options[:labels].is_a?(Array)
        options[:labels].each do |tmp_label_radio_button|
          label = tmp_label_radio_button.is_a?(Array) ? tmp_label_radio_button[0] : tmp_label_radio_button
          value = tmp_label_radio_button.is_a?(Array) ? tmp_label_radio_button[1] : tmp_label_radio_button
          html_option_one = html_options.clone
          html_option_one[:checked] = "checked" if options[:value]==value
          field_result += label_tag("#{options[:instance].presence}_#{options[:field].presence}_#{value.gsub(' ','_')}", radio_button(options[:instance].presence, options[:field].presence, value, html_option_one)  + " " + label,{:class => "radio-inline"} ).html_safe + "&nbsp;&nbsp;".html_safe
        end
      when "file"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " filepicker"
        html_options[:rel]      = options[:option_file].presence|| ((options[:directory].presence||"public") + ";/upload/content;[DIR],[EMPTY]") 
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options ) 
      when "font"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " fontpicker"
        field_result = "<div class='input-group #{bootstrap_length ? 'col-md-6' : ''}'>".html_safe +
                         text_field(options[:instance].presence, options[:field].presence,html_options ) +
                       "</div>".html_safe
      when "color"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " colorpicker"
        field_result = "<div class='input-group #{bootstrap_length ? 'col-md-2' : ''}'>".html_safe +
                         text_field(options[:instance].presence, options[:field].presence,html_options ) +
                       "</div>".html_safe
      when "video"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " filepicker"
        html_options[:rel]      = (options[:directory].presence||"public") + ";/upload/content;avi,wmv,[EMPTY],[DIR]" 
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options ) 
      when "css"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " filepicker"
        html_options[:rel]      = (options[:directory].presence||"public") + ";/upload/content;css,[EMPTY],[DIR]" 
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options ) 
      when "image"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " filepicker"
        html_options[:rel]      = (options[:directory].presence||"public") + ";/upload/content;jpg,png,[DIR],[EMPTY]" 
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options ) 
      when "directory"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " filepicker"
        html_options[:rel]      = (options[:directory].presence||"public") + ";/upload/content;[SELECTABLE],[DIR],[EMPTY]" 
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options ) 
      when "sound"
        html_options[:readonly] = options[:read_only].presence||false
        html_options[:class]   += " filepicker"
        html_options[:rel]      = (options[:directory].presence||"public") + ";/upload/content;mp3,ogg,wav,[EMPTY],[DIR]" 
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options ) 
      when "text_only"
        html_options[:class]   += " form-control-static" if bootstrap
        field_result = content_tag(:p, options[:value].presence, html_options)
      end
      
      if bootstrap_form
        label_result = generate_label(field_mandatory + tmp_label,options[:instance].presence,options[:field].presence,"col-sm-3 control-label")
        help_text_result = (options[:help_text].presence||"").blank? ? "" : "<span class='help-block'>#{options[:help_text]}</span>".html_safe        
        tmp_result = content_tag(:div, label_result + content_tag(:div, field_result + help_text_result, :class=> "col-sm-8"), :class => 'form-group')
      else
        label_result = generate_label(tmp_label,options[:instance].presence,options[:field].presence)
        tmp_result = label_result + field_result + field_mandatory
      end
      
      return tmp_result

    end    


    def generate_label(label="",instance="instance",field="field",classes="")
      tmp_for = (instance.blank? || field.blank?) ? "" : "#{instance}_#{field}"
      if label.blank?
        return ""
      elsif label == "[EMPTY]"
        return label_tag("", "&nbsp;".html_safe, :class => classes )
      else
        return label_tag(tmp_for, label + " : ", :class => classes )
      end
    end

    def help(method="",options={})
      text_title      = "<strong><p>easy_tag - help</p></strong>"
      help_text_first = "Syntaxe : easy_tag( \"#{method}\" , options={} )<BR><BR>"
      text_check      = check(method,options) 
      if ACTION[method.to_sym].present?
        help_text = help_text_first + text_check + help_options(method,ACTION[method.to_sym],options) 
      else  
        help_text = "Choisissez un code parmi : #{ACTION.keys.join(', ')}<br>ex: easy_tag(\"#{ACTION.keys[0]}\")"
      end
      return "<div class='alert alert-warning'>#{text_title}#{help_text}<BR></div><BR><BR>" 
    end
    
    def help_options(method,options,option_used)
      text_option = "<TR><TH>Option pour #{method}</TH><TH>Description</TH><TH>Obligatoire</TH><TH>Défaut</TH><TH>Utilisé</TH></TR>"
      (options + ["-Options technique",:help]).each do |opt|
        if OPTIONS[opt.to_sym].present?
          text_option += "<TR><TD>#{opt}</TD><TD>#{OPTIONS[opt.to_sym][:description]}</TD><TD>#{OPTIONS[opt.to_sym][:mandatory] ? "V" : ""}</TD><TD>#{OPTIONS[opt.to_sym][:default_value]}</TD><TD>#{option_used[opt.to_sym]||""}</TD></TR>"
        elsif opt[0..1] == '--'
          text_option += "<TR><TD colspan=5>#{opt[2..-1]}</TD></TR>"
        elsif opt[0] == '-'
          text_option += "<TR><TH colspan=5>#{opt[1..-1]}</TH></TR>"
        end
      end
      "<TABLE border=1>#{text_option}</TABLE>"
    end

    def check(method,options)
      text_check = ""
      ACTION[method.to_sym].each do |opt|
        text_check += "L'option '#{opt}' est obligatoire.<BR>" if OPTIONS[opt.to_sym].present? && OPTIONS[opt.to_sym][:mandatory] == true && options[opt.to_sym].presence.nil?
      end if ACTION[method.to_sym].present?
      return text_check.blank? ? "" : "Erreur(s) :<BR>#{text_check}<BR>"
    end

    def get_html_options(method, options)
      html_options={}
      ACTION[method.to_sym].each do |opt|
        html_options[opt.to_sym] = (options[opt.to_sym] || OPTIONS[opt.to_sym][:default_value].presence) if OPTIONS[opt.to_sym].present? && OPTIONS[opt.to_sym][:html_option] && options[opt.to_sym].present?
      end if ACTION[method.to_sym].present?
      return html_options 
    end

end
