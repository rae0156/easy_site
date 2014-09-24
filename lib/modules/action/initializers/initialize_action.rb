

  def generate_action(action_id,options={})

    text = ""
    action_id ||=0
    action_user = ActionUser.find_by_id(action_id)
    
    if action_user
      tmp_action,options_parameters = action_user.get_action_and_parameters
      description     = options[:link_description].presence || options_parameters[:link_description].presence || action_user.description
      target          = options[:link_target].presence || options_parameters[:link_target].presence || "_self"
      image_name      = options[:link_image_name].presence || options_parameters[:link_image_name].presence || "appli/execute_32.png"
      image_with_text = options[:link_image_with_text].presence || options_parameters[:link_image_with_text].presence || "Y"
      link_class      = options[:link_class].presence || options_parameters[:link_class].presence || "btn btn-default" 
      x               = options[:link_x].presence || options_parameters[:x].presence || 0 
      y               = options[:link_y].presence || options_parameters[:y].presence || 0 
      no_link         = options[:no_link].presence || options_parameters[:no_link].presence || "N" 
      
      style = (x==0 && y==0) ? "style='z-index:999;'" : "style='position: absolute;left: #{x}px;top: #{y}px; z-index:999;'"
      
      
      is_asset_image  = !Rails.application.assets.find_asset(image_name).nil?
      unless is_asset_image
        image_name = image_name[6..-1] if image_name.starts_with?("public")
        check_name = image_name.starts_with?(Rails.root) ? image_name : File.join(Rails.root,'public',image_name)
      end
      if is_asset_image || File.file?(check_name) 
        if image_with_text == "Y"
          element_shown = image_tag(image_name, {:alt => description}) + "#{'<BR/>' + description}".html_safe
        else
          element_shown = image_tag(image_name, {:alt => description})
        end
      else      
        element_shown = description
      end

      if no_link=="Y"
        text = element_shown
      else
        text = link_to(element_shown, url_for(:controller => "action_users",:action => "execute", :action_user => {:id => action_id}),:target => target)
      end
      text = "<div id='user_action_#{action_id}' class='#{link_class}' #{style}>#{text}</div>".html_safe
    end
    
    return text.html_safe
  end
