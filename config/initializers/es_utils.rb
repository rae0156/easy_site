  # encoding: UTF-8
  
  WillPaginate.per_page = 20
  
  require 'lorem'

  require 'spreadsheet' 
  Spreadsheet.client_encoding = 'UTF-8' 

  def init_workspace_easysite
    musique = EsSetup.get_setup("musique_site","")
    Rails.application.config.default_site             = EsSite.first(:conditions=>{:set_as_default => 'Y'}).id
    Rails.application.config.current_template         = ""
    Rails.application.config.current_theme            = ""
    Rails.application.config.current_musique          = musique.blank? ? "" : (EsSetup.get_setup("répertoire_musique","public/") + musique)
    Rails.application.config.default_locale_easysite  = :fr
    Rails.application.config.translation_mode         = EsSetup.get_setup("translation_mode","") #debug / with / [empty] = without    
  end
  
  def change_site_number(site_id,current_user)
    session[:current_site_id] = site_id
    EsSite.current_site_id=session[:current_site_id]
    
    #for user inputted, initialize default_site into db and reset session
    unless current_user.blank?
      EsSite.find_by_id(Rails.application.config.default_site).update_attribute('set_as_default','N')
      EsSite.find_by_id(site_id).update_attribute('set_as_default','Y')
      reset_session     
      init_workspace_easysite
    end
  end  
  
  def init_dynamic_attributes(file_to_load=nil)
    if file_to_load.blank?
      yml_file = File.join(Rails.root,"config","dynamic_attributes.yml")
    else
      yml_file = file_to_load
    end
    unless File.exist?(yml_file)
      puts "ERROR : Le fichier d'attributs dynamiques '#{yml_file}' n'existe pas"
      return false 
    end
    models_attrs = YAML.load(File.read(yml_file))  
    models_attrs.each do |models,categories|
      models.split(',').each do |model|
        begin
            model_class = model.constantize
        rescue 
        end


        if !class_exists?(model.to_s)
          puts "ERROR : Le modèle '#{model.to_s}' n'existe pas"  
        elsif !model_class.respond_to?("help_dyn_attr")
          puts "ERROR : Les attributs dynamiques ne sont pas activés pour le modèle '#{model.to_s}'" 
        else 
          categories.each do |category,groups|
            groups.each do |group,attrs|
              attrs.each do |attr,params|
                
                param_setup,type_setup,updatable,description,value_list,other_params,comments,length,mandatory = nil,nil,'Y','',nil,'','',nil,'N'
                params = params.strip
                if params.ends_with?(">>")
                  tmp_find = params.rindex('<<')
                  if !tmp_find.blank? && tmp_find>0
                    param_setup = params[tmp_find+2..-3].split('-')
                    params = params[0..tmp_find-1].rstrip
                  else
                    param_setup = params.strip[2..-3].split('-')
                    params = ""
                  end  
                end
                params =nil if params.blank?
                unless param_setup.blank?
                  tmp_type_setup  = param_setup[0].split('/') #ex : string/50
                  type_setup  = tmp_type_setup[0]
                  length      = tmp_type_setup[1]
                  updatable   = param_setup[1] || 'Y'
                  description = param_setup[2] || ''
                  mandatory = param_setup[4] || 'N'

                  if ["file"].include?(type_setup)
                    other_params  = param_setup[3] || ''
                  else
                    value_list = param_setup[3]
                    value_list.gsub!('[[DASH]]','-') unless value_list.blank?
                    other_params = param_setup[5] || ''
                  end
                end
                
                # puts "ici :  #{type_setup.inspect} #{updatable.inspect} #{description.inspect} #{value_list.inspect}#{other_params.inspect} #{category}/#{group}"
                model_class.define_attributes([{
                                                  :name          => attr, 
                                                  :type_data     => type_setup ,
                                                  :length        => length ,
                                                  :mandatory     => "N",
                                                  :default_value => params,
                                                  :choices       => value_list, 
                                                  :category      => "#{category}/#{group}",
                                                  :type_param    => other_params,
                                                  :comments      => description,
                                                  :read_only     => (updatable=='Y') ? "N" : "Y",
                                                  :mandatory     => mandatory
                                             }]) 
                
              end
            end if groups.is_a?(Hash)
          end if categories.is_a?(Hash)
        end

      end        
    end
    return true
  end
  
  def class_exists?(class_name)
    return Object.const_defined?(class_name)
  rescue 
    return false
  end
  
  
  def get_lorem
    Lorem::Base.new('words', 1000).output
  end

  #n'est utilisé que dans index de la vue site
  def get_content_detail(content_name,sequence=1)
    es_content = EsContent.find_by_name(content_name)
    es_content_detail = (es_content && !es_content.es_content_details.blank?) ? es_content.es_content_details.find_by_sequence(sequence) : nil
    return es_content_detail.blank? ? "" : get_template_part(es_content_detail.id)
  end

  def get_template_part(part_name,directory = "parts",partial=false,template_name=nil)
    if part_name.is_a?(Integer) #content_detail_id
        es_content_detail = EsContentDetail.find_by_id(part_name)
        if es_content_detail.blank?
          #error part
          return render(:partial => "layouts/part_error", :locals => {:part_name => part_name, :template_name => Rails.application.config.current_template})
        else
          #from setup part
          es_content_details = generate_tag(:div, es_content_detail.content, EsContent.prepare_properties(es_content_detail))
          return render(:inline => es_content_details)
        end
    else
      if template_name.blank?
        
        template_name = get_caller_template           
            
        unless template_name.blank?
          #create template and part + line and col + content + content detail if does not exist    
          template = EsTemplate.find_by_name(template_name)
          template = EsTemplate.create({:name => template_name, :description => template_name, :es_category_id => EsCategory.get_id("Site","template")}) if template.blank?
          #if EsPart.is_dynamic(part_name, directory)
            part = template.es_parts.find_by_name(part_name)
            part = template.es_parts.create({:name => part_name, :description => part_name, :num => 1}) if part.blank?
            line = template.es_template_lines.find_by_num(part.id)
            line = template.es_template_lines.create({:es_col_parent_id => 0, :num => part.id}) if line.blank?
            col  = line.es_template_cols.find_by_num(1)
            if col.blank?
              col  = line.es_template_cols.create({:num => 1, :width => 12, :description => part_name}) 
            else
              col.update_attribute('description', part_name)
            end
            part.update_attributes(:es_template_col_id => col.id)
          if EsPart.is_dynamic(part_name, directory)
            content = EsContent.find_by_name(part_name)
            if content.blank?
              content = EsContent.create({:name => part_name})
              part.update_attributes(:es_content_id => content.id)
            end
            if content.es_content_details.size == 0
              content_detail = content.es_content_details.create({:sequence => 1, :content => "", :editable => 'Y', :content_type => "dynamic"})
              content_detail.update_attribute("content","<%= generate_dynamic_part(#{content_detail.id})%>") 
            end          
            
          end
        else
          template_name=Rails.application.config.current_template
        end
      end
      tmp_layout = directory + '/_' + part_name
      if lookup_context.find_all(tmp_layout).any?
        #find existing part
        if partial          
          return render(:partial=> tmp_layout.gsub('/_','/'))
        else
          text = render(tmp_layout.gsub('/_','/'))
          return text
        end
      else
        #find setup for current template
        conditions = ["es_templates.name = ? AND es_parts.name = ? ", 
                    template_name,
                    part_name
                    ] 
        es_content_details = EsContentDetail.find(:all, :order => "es_content_details.sequence", :conditions => conditions, :include => [:es_content => [:es_parts => :es_template]])
        
        if es_content_details.size == 0
          #error part
          return render(:partial => "layouts/part_error", :locals => {:part_name => tmp_layout, :template_name => template_name})
        else
          #from setup part
          es_content_text = ""
          es_content = es_content_details.first.es_content
          es_content_details.each do |cd|
            properties = EsContent.prepare_properties(cd)
            es_content_text += properties.blank? ? cd.content : generate_tag(:div, cd.content, properties)
          end
          
          properties  = EsContent.prepare_properties(es_content)
          es_content_text = generate_tag(:div, es_content_text, properties) unless properties.blank?
          
          return render(:inline => es_content_text)
        end
      end
    end
  end
  
  def get_caller_template
    #can be caller.first : file template => get_template_part 
    #    or caller[1]    : file template => get_template_file_part => get_template_part 
    #    or caller[2] 
    tmp_caller=caller.clone
    
    tmp_template_full_name = ""
    (0..2).each do |i|
      tmp_template_full_name = tmp_caller[i] if tmp_caller[i].split('/')[-2] == "templates"
    end

    if !tmp_template_full_name.blank?
      return tmp_template_full_name.split('/').last.split('.').first[1..-1]
    else
      return ""
    end
  end

  def create_dir(*tmp_dirs)    
    tmp_dirs = File.join(Rails.root,tmp_dirs)
    FileUtils.mkdir_p(tmp_dirs) unless File.exist?(tmp_dirs)
  end      

  def remove_file(file_name)
    File.delete(file_name)
  end


  def save_upload(upload,directory)
    name =  upload['datafile'].original_filename
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
  end


  def generate_anchor(part_name,link_text='')
    if link_text.blank?
      return "<a name='anchor_#{part_name}'></a>".html_safe
    else
      return link_to(link_text,url_for(:anchor => 'anchor_' + part_name)) 
    end
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

  
  
  def test_url(string)
    return true if EsSetup.get_setup("test_url",'N')=='N'
    url = URI.parse(string)
    res_start = Net::HTTP.start(url.host, url.port) do |http|
      res = Net::HTTP.get_response(url)
      return res.code.to_i >= 200 && res.code.to_i < 400 #good codes will be betweem 200 - 399
    end
  rescue
    false
  end    


  def color_hex_to_rgba(input,opacity=1)
    a = ( input.match /#(..?)(..?)(..?)/ )[1..3]
    a.map!{ |x| x + x } if input.size == 4
    "rgba(#{a[0].hex},#{a[1].hex},#{a[2].hex},#{opacity})"
  end

  def get_image_name(file_name)
    check_name = ""
    is_asset_image  = !Rails.application.assets.find_asset(file_name).nil?
    unless is_asset_image
      tmp_image_name = file_name.starts_with?("public") ? file_name[6..-1] : file_name
      check_name = tmp_image_name.starts_with?(Rails.root) ? tmp_image_name : File.join(Rails.root,'public',tmp_image_name)
    else
      tmp_image_name = file_name
    end
    if is_asset_image || File.file?(check_name) 
      return tmp_image_name
    else
      return ""
    end
  end

  def sanitize_filename(filename,add_caract='')
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
  
    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-#{add_caract}]+/i, '_' }
  
    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end



class Numeric
    def nice_bytes( max_digits=3 )
      bytes = self.to_i
      value_K = 2.0**10
      value_M = 2.0**20
      value_G = 2.0**30
      value_T = 2.0**40
      value, suffix, precision = case bytes
        when 0...value_K
          [ bytes, 'octets', 0 ]
        else
          value, suffix = case bytes
            when value_K...value_M then [ bytes / value_K, 'ko' ]
            when value_M...value_G then [ bytes / value_M, 'Mo' ]
            when value_G...value_T then [ bytes / value_G, 'Go' ]
            else                        [ bytes / value_T, 'To' ]
          end
          used_digits = case value
            when   0...10   then 1
            when  10...100  then 2
            when 100...1024 then 3
          end
          leftover_digits = max_digits - used_digits
          [ value, suffix, leftover_digits > 0 ? leftover_digits : 0 ]
      end
      number = ("%.#{precision}f" % value).to_f
      (number.to_i == number ? number.to_i : number).to_s + " #{suffix}"
    end
end    

class Object
  def multi_send(send_string)
      tmp_value=self
      send_string.split('.').each do |to_send|
        tmp_value=tmp_value.send(to_send)
      end  
      tmp_value
  end
  
end    


class String

  def is_numeric?
    true if Float(self) rescue false
  end
  def is_integer?(length=99)
    if Integer(self) && !self.include?(",") && !self.include?(".")
      self.length <= length
    else
      false
    end 
    rescue 
      return false
  end


  def limit(nbr,types='text')
    if self.length>nbr
      text = self[0..nbr-4]
      if !(types=='text') and text.index(',') > 0
        text = text[0..text.rindex(',')-1]
      end
      text + '...'      
    else
      self
    end
  end

  def trn(options={})
    begin
      text_traduct = EsLanguage.trn(self,(Rails.application.config.default_locale_easysite||:fr),options)
    rescue => e  
      text_traduct = self
    end
    
#    text_code = self
#    default = Rails.env.downcase == 'development' ? "#{text_code} <<<PAS DE TRADUCTION" : text_code
#    options[:default]||=default
#    text_traduct = I18n.t(text_code,options)
    return text_traduct
  end
  
  
  
end

