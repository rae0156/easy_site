# encoding: UTF-8

module EasyHelper
    ACTION = {
              :label            => ["label","for","-Options html","class","style"], 
              :text             => ["instance","field","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"],
              :long_text        => ["instance","field","value","cols","rows","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"],
              :check_box        => ["instance","field","value","checked_value","unchecked_value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :list             => ["instance","field","value_list_array","selected_value","-Options visuelles","include_blank","number_of_line","multiple","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"],
              :list_collection  => ["instance","field","collection","value_method","text_method","selected_value","-Options visuelles","include_blank","number_of_line","multiple","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"],
              :radio_button     => ["instance","field","labels","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"],
              :mandatory        => ["label","-Options html","class","style"], 
              :integer          => ["--Ne pas oublier le javascript 'init_inputmask();'","instance","field","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :decimal          => ["--Ne pas oublier le javascript 'init_inputmask();'","instance","field","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :date             => ["--Ne pas oublier le javascript 'init_datepicker();'","instance","field","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :time             => ["--Ne pas oublier le javascript 'init_datepicker();'","instance","field","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :date_time        => ["--Ne pas oublier le javascript 'init_datepicker();'","instance","field","value","-Options html","class","style","read_only","-Options additionnelles","with_label","ajax_action","mandatory"], 
              :hidden           => ["instance","field","value","-Options html","class"]
              }
    OPTIONS = {
                :help               => {:mandatory => false , :html_option => false, :description => "true = pour avoir l'aide en plus de la génération"}, 
                :label              => {:mandatory => true  , :html_option => false, :description => "Libellé"}, 
                :labels             => {:mandatory => true  , :html_option => false, :description => "Libellé ou liste de libellés"}, 
                :for                => {:mandatory => false , :html_option => false, :description => "Liaison avec un champs (instance_champs)"}, 
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
                :with_label         => {:mandatory => false , :html_option => false, :description => "ajoute un libellé"}
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
    
    
    
private

    def gererate_easy_tag(method,options)
      field_options={}
      html_options=get_html_options(method, options)
      label_result = options[:with_label].present? ? generate_label(options[:with_label],options[:instance].presence,options[:field].presence) : ""
      field_mandatory = (options[:mandatory].presence || false) ? "<span class=\"text-error\">*</span>".html_safe : ""
      
      field_result = ""
      case method
      when "label"
        field_result = label_tag(options[:for].presence || "", options[:label].presence,html_options )
      when "mandatory"
        field_result = "<span class=\"text-error\">*</span><span class=\"text-error\">#{options[:label].presence}</span>".html_safe
      when "text"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options )
      when "integer"
        html_options[:readonly]=options[:read_only].presence||false
        html_options[:class]             = "" unless html_options[:class].present?
        html_options[:class]            += " inputmask"
        html_options["data-inputmask"]   = "'alias': 'integer'"
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options)
      when "decimal"
        html_options[:readonly]=options[:read_only].presence||false
        html_options[:class]             = "" unless html_options[:class].present?
        html_options[:class]            += " inputmask"
        html_options["data-inputmask"]   = "'alias': 'decimal', 'groupSeparator': ',', 'autoGroup': true"
        field_result = text_field(options[:instance].presence, options[:field].presence,html_options)
      when "date_time"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = "<div class='input-append date' data-behaviour='datetimepicker' data-date='#{options[:value].presence}'>".html_safe +
                       text_field(options[:instance].presence, options[:field].presence,html_options) +
                       "<span class='add-on'><i class='icon-th'></i></span></div>".html_safe
      when "date"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = "<div class='input-append date' data-behaviour='datepicker' data-date='#{options[:value].presence}'>".html_safe +
                       text_field(options[:instance].presence, options[:field].presence,html_options) +
                       "<span class='add-on'><i class='icon-th'></i></span></div>".html_safe
      when "time"
        html_options[:readonly]=options[:read_only].presence||false
        field_result = "<div class='input-append date' data-behaviour='timepicker' data-date='#{options[:value].presence}'>".html_safe +
                       text_field(options[:instance].presence, options[:field].presence,html_options) +
                       "<span class='add-on'><i class='icon-th'></i></span></div>".html_safe
      when "long_text"
        html_options[:disabled]=((options[:read_only].presence||false) ? "disabled" : false)
        field_result = text_area(options[:instance].presence, options[:field].presence,html_options )
      when "list", "list_collection"
        html_options[:disabled]=((options[:read_only].presence||false) ? "disabled" : false)
        html_options[:size]= options[:number_of_line] || 1
        field_options[:include_blank] = options[:include_blank].presence||true
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
      when "hidden"
        field_result = hidden_field(options[:instance].presence, options[:field].presence, html_options)
      when "check_box"
        html_options[:readonly]=options[:read_only].presence||false
        html_options[:checked] = "checked" if options[:value]==(options[:checked_value]||"Y")
        field_result = check_box(options[:instance].presence, options[:field].presence,html_options, options[:checked_value]||"Y", options[:unchecked_value]||"N")
      when "radio_button"
        html_options[:disabled]=options[:read_only].presence||false
        field_result="".html_safe
        options[:labels] = [options[:labels]] unless options[:labels].presence.is_a?(Array)
        options[:labels].each do |label|
          html_option_one = html_options.clone
          html_option_one[:checked] = "checked" if options[:value]==label
          field_result += label_tag("#{options[:instance].presence}_#{options[:field].presence}_#{label.gsub(' ','_')}", label ) + "&nbsp;".html_safe + radio_button(options[:instance].presence, options[:field].presence, label, html_option_one) + "&nbsp;".html_safe
        end
      end
      
      return label_result + field_result + field_mandatory

    end    




    def generate_label(label="",instance="instance",field="field")
      return label_tag("#{instance}_#{field}", label ) + " : "
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
      return "<div class='alert '>#{text_title}#{help_text}</div><BR><BR>" 
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