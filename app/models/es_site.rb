# encoding: UTF-8

class EsSite < ActiveRecord::Base
  cattr_accessor  :current_site_id

  acts_as_dynamic_model([{:name => "code",
                          :field_key => true,
                          :mandatory => true,
                          :column_name => 'Nom du site'
                          },
                         {:name => "description",
                          :mandatory => true,
                          :column_name => 'Description'}
                         ],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {},
                  :model_audit_label  => "Site".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.code
  end
  
  
  def complete_name
    "#{self.code} - #{self.description}"
  end
  
  def self.delete_a_site
    es_site = EsSite.find_by_id(EsSite.current_site_id)
    if es_site
      Dir[Rails.root + 'app/models/**/*.rb'].each do |path|
        require path
      end
      ActiveRecord::Base.descendants.each do |model|
        model = model.name.constantize
        if model.column_names.include?("es_site_id") && model.all.count > 0
          model.delete_all(:es_site_id => EsSite.current_site_id)
        end
      end
      es_site.destroy 
    end
  end

  def self.export_model_to_yaml(model_name,path_file_name=nil,exclude_fields=[])
    yml_file = path_file_name || (Rails.root.join(Rails.root,"config","#{model_name}.yml"))
    File.open(yml_file, 'w',external_encoding: 'ASCII-8BIT') do |file|
      model_name = model_name.classify
      begin
          model_class = model_name.constantize
      rescue 
      end    
      if class_exists?(model_name.to_s) 
        YAML::dump(model_class.find(:all).map{|e| e.attributes.except(*exclude_fields)}, file)
      end
    end    
  end

  def self.create_a_site(is_refresh_mode='N')
    log_error
    @key_fields={}
    es_site = EsSite.find_by_id(EsSite.current_site_id)
    if es_site
      yml_file = File.join(Rails.root,"config","new_site_data.yml")
      if File.exist?(yml_file)
        tables = YAML.load(File.read(yml_file))  
        tables.each do |table_name,table|
          model_name = table_name.classify
          begin
              model_class = model_name.constantize
          rescue 
          end    
          if class_exists?(model_name.to_s) 
            create_an_array_of_record(table,model_class,is_refresh_mode)
          else
            log_error "Le modèle '%{model}' n'existe pas ou n'est pas défini".trn(:model => model_name)
          end
        end
      end
    end
    @error_lines
  end
  
private

  def self.create_an_array_of_record(table,model_class,is_refresh_mode='N')
    ids = []
    model_name = model_class.to_s
    @key_fields[model_name] = table['keys'].split(',') if table['keys'].present? && !@key_fields[model_name].present?
    if @key_fields[model_name].present?
      if !@key_fields[model_name].blank?
        if table['rows'].present? && table['rows'].is_a?(Array)
          linked_model_list = get_linked_model_list(model_class)
          table['rows'].each do |row|
            id = create_a_record(row,model_class,linked_model_list,is_refresh_mode)
            ids << id unless id.blank?
          end
        else
          log_error "Il n'y a pas de ligne à charger pour le modèle '%{model}'".trn(:model => model_name)
        end
      else
        log_error "La clé est vide le modèle '%{model}'".trn(:model => model_name)
      end
    else
      log_error "La clé unique n'est pas définie pour le modèle '%{model}'".trn(:model => model_name)
    end
    return ids
  end

  def self.create_a_record(row,model_class,linked_model_list,is_refresh_mode='N')
    model_name = model_class.to_s
    return_id = nil
    key_fields=@key_fields[model_class.name]
    tmp_row={}
    row.each do |attr,value|

      if value.is_a?(Hash)
        if model_class.new.respond_to?(attr.to_s) && linked_model_list[attr.to_s].present?
          unless value["rows"].present?
            model_class_linked = linked_model_list[attr.to_s].constantize
            id = create_a_record(value,model_class_linked,get_linked_model_list(model_class_linked), is_refresh_mode)
            tmp_row[attr + "_id"] = id unless id.blank?
          end
        else
          log_error "Erreur lors de la création de d'un élément dans le modèle '%{model}' : l'attribut '%{attr}' n'existe pas".trn(:model => model_name, :attr => attr)          
        end
      elsif !value.is_a?(Array)
        tmp_row[attr] = value
      end
    end
    
    key_attribute=tmp_row.slice(*key_fields)
    if (element = model_class.find(:first,:conditions=> key_attribute)).blank? 
      action_element='création'.trn
      element = model_class.new(tmp_row)
    else
      action_element='modification'.trn
      return_id = element.id     
      if is_refresh_mode=='N'
        log_error "L'élément '%{element}' existe déjà pour le modèle '%{model}'".trn(:model => model_name, :element => key_attribute.inspect) unless key_fields.sort == tmp_row.keys.sort
      else
        element.attributes = tmp_row
      end
    end
    
    if @error_lines.empty?
      element.valid?
      if element.errors.empty?
        element.save

        #######################################################
        # special pour remplacer [[ID]] par l'id de l'élément #
        #######################################################
        save_again = false
        tmp_row.each do |k,v|
          if !v.to_s.index("[[ID]]").nil?
            element[k] = v.gsub('[[ID]]',element.id.to_s)
            save_again = true
          end
        end
        element.save if save_again
        #######################################################

        return_id = element.id
      else
        element.errors.map do |attribute, message| 
          if message[0]== '#'
            err = message[1..-1]
          else
            err = object.errors.full_message(attribute, message)
          end 
          log_error "Erreur lors de la %{action} de l'élément '%{element}' dans le modèle '%{model}' : %{err}".trn(:action => action_element, :model => model_name, :element => key_attribute.inspect, :err => err)
        end
      end
    end
    
    if @error_lines.empty? && !return_id.nil?
      return_id = nil
      tmp_row={}
      row.each do |attr,value|
  
        if value.is_a?(Hash)
          if model_class.new.respond_to?(attr.to_s) && linked_model_list[attr.to_s].present?
            if value["rows"].present?
              model_class_linked = linked_model_list[attr.to_s].constantize
              ids = create_an_array_of_record(value, model_class_linked,is_refresh_mode)
              tmp_row[attr.singularize + "_ids"] = ids unless ids.blank?
            end
          else
            log_error "Erreur lors de la création de d'un élément dans le modèle '%{model}' : l'attribut '%{attr}' n'existe pas".trn(:model => model_name, :attr => attr)          
          end
        elsif value.is_a?(Array)
          #pour éliminer un cas d'erreur, on ne prend pas en compte les array
          model_class_linked = linked_model_list[attr.to_s].constantize
          ids = create_an_array_of_record({'rows'=> value}, model_class_linked,is_refresh_mode)
          tmp_row[attr.singularize + "_ids"] = ids unless ids.blank?
        end
      end
      element.attributes = tmp_row
      element.valid?
      if element.errors.empty?
        element.save
        return_id = element.id
      else
        element.errors.map do |attribute, message| 
          if message[0]== '#'
            err = message[1..-1]
          else
            err = object.errors.full_message(attribute, message)
          end 
          log_error "Erreur lors de la création de l'élément '%{element}' dans le modèle '%{model}' : %{err}".trn(:model => model_name, :element => key_attribute.inspect, :err => err)
        end
      end      
    end
    return return_id
  end

  def self.get_linked_model_list(model_class)
    linked_model_list={}
    model_class.reflect_on_all_associations.each do |elem|
      case elem.macro.to_s
      when "has_many", "has_and_belongs_to_many" 
        linked_model_list[elem.name.to_s] = elem.options[:class_name].presence||elem.name.to_s.singularize.classify
      when "belongs_to", "has_one"
        linked_model_list[elem.name.to_s] = elem.options[:class_name].presence||elem.name.to_s.classify  
      end
    end
    
    return linked_model_list
  end

  def self.log_error(line=nil)
    if line.nil?
      @error_lines=[]
    else
      @error_lines << line
    end
  end
end