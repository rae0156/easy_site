  
  WillPaginate.per_page = 20
  
  require 'lorem'

  def init_workspace_easysite
    Rails.application.config.default_site             = EsSite.first(:conditions=>{:set_as_default => 'Y'}).id
    Rails.application.config.current_template         = ""
    Rails.application.config.current_theme            = ""
    Rails.application.config.default_locale_easysite  = :fr
    Rails.application.config.translation_mode         = EsSetup.get_setup("translation_mode","") #debug / with / [empty] = without    
  end
  
  
  def init_dynamic_attributes
    yml_file = File.join(Rails.root,"config","dynamic_attributes.yml")
    unless File.exist?(yml_file)
      puts "Le fichier d'attributs dynamiques '#{yml_file}' n'existe pas"
      return false 
    end
    models_attrs = YAML.load(File.read(yml_file))  
    models_attrs.each do |models,categories|
      models.split(',').each do |model|
        begin
            model_class = model.constantize
        rescue 
        end
  
        if class_exists?(model.to_s) && model_class.respond_to?("help_dyn_attr") 
          categories.each do |category,groups|
            groups.each do |group,attrs|
              attrs.each do |attr,params|
                
                param_setup,type_setup,updatable,description,value_list,other_params,comments = nil,nil,'N','',nil,'',''
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
                  type_setup  = param_setup[0]
                  updatable   = param_setup[1] || 'Y'
                  description = param_setup[2] || ''
                  if ["file"].include?(type_setup)
                    other_params  = param_setup[3] || ''
                  else
                    value_list = param_setup[3]
                  end
                end
                
                # puts "ici :  #{type_setup.inspect} #{updatable.inspect} #{description.inspect} #{value_list.inspect}#{other_params.inspect} #{category}/#{group}"
                model_class.define_attributes([{
                                                  :name          => attr, 
                                                  :type_data     => type_setup ,
                                                  :mandatory     => "N",
                                                  :default_value => params,
                                                  :choices       => value_list, 
                                                  :category      => "#{category}/#{group}",
                                                  :type_param    => other_params,
                                                  :comments      => description
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
    Lorem::Base.new('words', 100).output
  end

  def get_content_detail(content_name,sequence=1)
    es_content = EsContent.find_by_name(content_name)
    es_content_detail = (es_content && !es_content.es_content_details.blank?) ? es_content.es_content_details.find_by_sequence(sequence) : nil
    return es_content_detail.blank? ? "" : get_template_part(es_content_detail.id)
  end

  def generate_template_render(template_name)
    template = EsTemplate.find_by_name(template_name)
    if template  
      parts_containt = {}
      template.es_parts.each do |p|
        parts_containt[p.name] = get_template_part(p.name) unless p.es_template_col_id == 0
      end
      return render(:inline => template.generate_template_for_render(parts_containt))
    else
      return render(:inline => "<p>" + "Le template %{name} n'existe pas".trn(:name=> template_name) +"</p>")
    end
  end

  def get_template_part(part_name,directory = "parts",partial=false)
    if part_name.is_a?(Integer)
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
      if caller.first.split('/')[-2] == "templates"
        template_name = caller.first.split('/').last.split('.').first[1..-1]
        #create template and part if does not exist    
        template = EsTemplate.find_by_name(template_name)
        template = EsTemplate.create({:name => template_name, :description => template_name, :es_category_id => EsCategory.get_id("Site","template")}) if template.blank?
        if EsPart.is_dynamic(part_name, directory)
          part = template.es_parts.find_by_name(part_name)
          part = template.es_parts.create({:name => part_name, :description => part_name, :num => 0}) if part.blank?
        end
      else
        template_name=Rails.application.config.current_template
      end

      tmp_layout = directory + '/_' + part_name
      if lookup_context.find_all(tmp_layout).any?
        #find existing part
        if partial          
          return render(:partial=> tmp_layout.gsub('/_','/'))
        else
          return render tmp_layout.gsub('/_','/')
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

  def create_dir(*tmp_dirs)    
    tmp_dirs = File.join(Rails.root,tmp_dirs)
    FileUtils.mkdir_p(tmp_dirs)
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
    url = URI.parse(string)
    res_start = Net::HTTP.start(url.host, url.port) do |http|
      res = Net::HTTP.get_response(url)
      return res.code.to_i >= 200 && res.code.to_i < 400 #good codes will be betweem 200 - 399
    end
  rescue
    false
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

