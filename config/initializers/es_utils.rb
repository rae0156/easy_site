  
  WillPaginate.per_page = 20
  
  require 'lorem'
  
  def get_lorem
    Lorem::Base.new('words', 100).output
  end

  def get_content_detail(content_name,sequence=1)
    es_content = EsContent.find_by_name(content_name)
    es_content_detail = (es_content && !es_content.es_content_details.blank?) ? es_content.es_content_details.find_by_sequence(sequence) : nil
    return es_content_detail.blank? ? "" : get_template_part(es_content_detail.id)
  end

  def get_template_part(part_name)
    
    if part_name.is_a?(Integer)
        es_content_detail = EsContentDetail.find_by_id(part_name)
        if es_content_detail.blank?
          #error part
          return render(:partial => "layouts/part_error", :locals => {:part_name => part_name, :template_name => Rails.application.config.current_template})
        else
          #from setup part
          es_content_details = es_content_detail.content
          #return render(:partial => "layouts/part_from_setup", :locals => {:content => es_content_details})
          
          return render(:inline => es_content_details)
        end
    else
      if caller.first.split('/')[-2] == "templates"
        template_name = caller.first.split('/').last.split('.').first[1..-1]
        #create template and part if does not exist    
        template = EsTemplate.find_by_name(template_name)
        template = EsTemplate.create({:name => template_name, :description => template_name, :es_category_id => EsCategory.get_id("Site","template")}) if template.blank?
        part = template.es_parts.find_by_name(part_name)
        part = template.es_parts.create({:name => part_name, :description => part_name}) if part.blank?
      else
        template_name=Rails.application.config.current_template
      end
  
      tmp_layout = 'layouts/_' + part_name
      if lookup_context.find_all(tmp_layout).any?
        #find existing part
        return render tmp_layout.gsub('/_','/')
      else
        #find setup for current template
        conditions = ["es_templates.name = ? AND es_parts.name = ? ", 
                    template_name,
                    part_name
                    ] 
        es_content_details = EsContentDetail.find(:all, :order => "es_content_details.sequence", :conditions => conditions, :include => [:es_content => [:es_parts => :es_template]])
        
        if es_content_details.blank?
          #error part
          return render(:partial => "layouts/part_error", :locals => {:part_name => tmp_layout, :template_name => template_name})
        else
          #from setup part
          es_content_details = es_content_details.collect(&:content).join
          #return render(:partial => "layouts/part_from_setup", :locals => {:content => es_content_details})
          
          return render(:inline => es_content_details)
        end
      end

    end
    
    
  end

  def create_dir(*tmp_dirs)    
    tmp_dirs = File.join(Rails.root,tmp_dirs)
    FileUtils.mkdir_p(tmp_dirs)
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
end

