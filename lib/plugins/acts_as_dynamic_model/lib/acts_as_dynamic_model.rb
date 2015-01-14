# encoding: UTF-8
# ActAsDynamicModel

module ActsAsDynamicModel
     
  module AddActAsMethods
    
    def self.included(base)
     base.send :extend , ClassMethods
     base.send :include, InstanceMethods
    end  
    
    
    module ClassMethods

      def acts_as_dynamic_model(columns=[],options={})
        
    #      named_scope :all_active  , :conditions => ["NVL(#{self.table_name}.active, 'Y') = 'Y' "]
    #      named_scope :all_inactive, :conditions => ["#{self.table_name}.active = 'N'"]
        
        unless self.table_name.blank?
          
          before_validation :manage_dynamic_default, :on => :create    
          before_save   :upper_case_dynamic
          before_save   :read_only_assign , :on => :create
          self.init_setup(columns,options) 
          self.dynamic_validation
        end        
      end
      
      def init_setup(columns,options)
        @setup_model=options
        @setup_model[:audit_model]            = @setup_model[:audit_model].nil?         ? true : @setup_model[:audit_model]    
        @setup_model[:fixed_attributes]       = @setup_model[:fixed_attributes].nil?    ? {} : @setup_model[:fixed_attributes]    
        @setup_model[:only_field_defined]     = @setup_model[:only_field_defined].nil?  ? false : @setup_model[:only_field_defined]    
        
        acts_as_multi_site if self.column_names.include?('es_site_id')  && self.respond_to?("acts_as_multi_site")
        stampable if (self.column_names.include?('creator_id') || self.column_names.include?('updater_id') || self.column_names.include?('created_by') || self.column_names.include?('updated_by')) && self.respond_to?("stampable")

        act_as_order_field = self.column_names.include?('sequence') ? "sequence" : (self.column_names.include?('name') ? "name" : "id")        
        acts_as_tree :order => act_as_order_field if self.column_names.include?('parent_id') && self.respond_to?("acts_as_tree")
        acts_as_audited if @setup_model[:audit_model]  && self.respond_to?("acts_as_audited")  
                
        linked_model_list = []
        self.reflect_on_all_associations.each do |elem|
          case elem.macro.to_s
          when "has_many", "has_and_belongs_to_many" 
            attr_accessible "#{elem.name.to_s.singularize}_ids"  
          when "belongs_to", "has_one"
            linked_model_list << elem.name.to_s.singularize
          end
        end
        
        columns_setup_forced = columns||[]
        columns_setup = []
        
        self.columns.each do |column|
          foreign = is_id(column) && linked_model_list.include?(column.name[0..-4]) 
          tmp_columns_setup= { :name                => column.name,
                               :mandatory           => ["name","code"].include?(column.name),
                               :column_name         => nil,
                               :label_name          => nil,
                               :length_min          => column.type.to_s=="string" ? (column.limit>10 ? -1 : column.limit) : -1,
                               :length_max          => column.type.to_s=="string" ? column.limit : -1,
                               :type                => is_boolean(column) ? "boolean" : column.type.to_s,
                               :field_key           => column.name == "code",
                               :field_key_scope     => "",
                               :value_list          => is_boolean(column) ? "Y,N" : "",
                               :link_field          => "",
                               :print               => !["id","created_at","updated_at","sequence","active","visible","creator_id","updater_id","created_by","updated_by","read_only"].include?(column.name),
                               :min_value           => nil,
                               :max_value           => nil,
                               :upper_case          => false,
                               :default_value       => (column.type.to_s=="string" && column.limit==1 && column.default=='Y') ? 'Y' : nil,
                               :order               => nil,
                               :order_load          => nil,
                               :foreign             => foreign, 
                               :hidden               => ["id","created_at","updated_at","creator_id","updater_id"].include?(column.name) #|| foreign
                              } 
          exist_columns_setup = columns_setup_forced.select{|col| col[:name]==column.name}
          exist_columns_setup = exist_columns_setup.blank? ? {} : exist_columns_setup[0]
          new_columns_setup = {}
          tmp_columns_setup.each do |key,value|
            new_columns_setup[key] = exist_columns_setup[key].nil? ? value : exist_columns_setup[key]
          end      

          if @setup_model[:only_field_defined] && exist_columns_setup.blank? 
            new_columns_setup[:name] = column.name
            new_columns_setup[:hidden] = true
          end

          columns_setup << new_columns_setup                          
        
        end
        columns_setup = columns_setup.select { |hsh| (hsh[:hidden]||false)==false } 
        

    #   fill order_load
        columns_setup.each do |hsh| 
          hsh[:order_load] = nil unless hsh[:export]
        end
        tmp_columns_order = columns_setup.collect{|hsh| hsh[:order_load]||0}
        index=0    
        columns_setup.each do |hsh| 
          if hsh[:order_load].blank? && hsh[:export]
            begin 
              index+=1
            end while tmp_columns_order.include?(index)
            hsh[:order_load]= index
          end
        end
   
        #sort column by order
        @columns_setup = columns_setup.sort_by { |hsh| hsh[:order]||0 }
      end

      def is_id(column)
        !column.name.match(/_id$/).nil?
      end

      def dynamic_validation
        multi_site = self.column_names.include?('es_site_id')  && self.respond_to?("acts_as_multi_site")
        @columns_setup.each do |column|
          attr_accessible column[:name].to_sym 

          validates_presence_of   column[:name].to_sym,:message => '#' + "'%{name}' ne peut pas être vide".trn(:name => column[:column_name]) if column[:mandatory]
          
          min_length = column[:length_min]||-1
          max_length = column[:length_max]||-1
          if max_length>-1 || max_length>-1
            if max_length==-1 and min_length > -1 
              validates_length_of     column[:name].to_sym, :minimum => min_length, :allow_blank => true,:message => '#' + "La valeur de '%{name}' doit avoir une longueur %{min} minimum".trn(:name => column[:column_name],:min => min_length)
            elsif max_length>-1 and min_length==-1 
              validates_length_of     column[:name].to_sym, :maximum => max_length, :allow_blank => true,:message => '#' + "La valeur de '%{name}' doit avoir une longueur %{max} maximum".trn(:name => column[:column_name],:max => max_length)
            elsif min_length == max_length
              validates_length_of     column[:name].to_sym, :is => min_length, :allow_blank => true,:message => '#' + "La valeur de '%{name}' doit avoir une longueur de %{min}".trn(:name => column[:column_name],:min => min_length)
            elsif 
              validates_length_of     column[:name].to_sym, :in => min_length..max_length, :allow_blank => true,:message => '#' + "La valeur de '%{name}' doit avoir une longueur entre %{min} et %{max}".trn(:name => column[:column_name],:min => min_length, :max => max_length)
            end
          end     
          

          case column[:type]
          when "float", "decimal"
            validates_numericality_of column[:name].to_sym, :allow_blank => true,:message => '#' + "La valeur de '%{name}' n'est pas numérique".trn(:name => column[:column_name])
          when "integer"
            validates_numericality_of column[:name].to_sym, :only_integer => true, :allow_blank => true,:message => '#' + "La valeur de '%{name}' n'est pas entière".trn(:name => column[:column_name])
          end if column[:name].match(/_id$/).nil? 

          validates_inclusion_of(column[:name].to_sym, 
                                 :in => (column[:value_list].is_a?(Array) ? column[:value_list] : column[:value_list].split(",")), 
                                 :message => '#' + "La valeur de '%{name}' n'est pas inclus dans la liste '%{liste}'".trn(:name => column[:column_name],:liste => column[:value_list])) if !column[:value_list].blank? && !column[:type] == 'list_multi'  
          
          
          if column[:field_key]
            scope = column[:field_key_scope].blank? ? [] : (column[:field_key_scope].split(",").map{|elem| elem.to_sym})  
            scope << :es_site_id if multi_site
            scope = nil if scope.size == 0
            validates_uniqueness_of(column[:name].to_sym, :case_sensitive => false, :scope => scope,:message => '#' + "La valeur de '%{name}' exist déjà".trn(:name => column[:column_name]))  
          end
        end
        validate :validate_dynamic
      end
    
      def setup_model
        @setup_model
      end
    
      def columns_setup
        @columns_setup
      end

      def get_header_csv
        header=[]        
        @columns_setup.sort_by { |hsh| hsh[:order_load]||0 }.each do |col|          
          header << col[:label_name] if (col[:order_load]||0) > 0 && col[:export] 
        end
        return header.join(';') 
      end
            
      def sanitize_filename(file_name)
        # get only the filename, not the whole path (from IE)
        just_filename = File.basename(file_name) 
        # replace all none alphanumeric, underscore or perioids
        # with underscore
        just_filename.sub(/[^\w\.\-]/,'_') 
      end
 
       def save_file(upload, options={})
        return if upload.blank?
        # create the file path    
        name  = options[:name] || Time.now.strftime('%Y%m%d%H%M%S') + "_" + self.sanitize_filename(upload.original_filename)    
        name  = "#{options[:prefix]}_#{name}" unless options[:prefix].blank?
    
        path = File.join(Rails.root, 'public', 'archives','in').freeze
        FileUtils.mkdir_p(path) unless File.directory?(path)
        
        path_file   = File.join(path, name)
        # write the file
        File.open(path_file, "wb") { |f| f.write(upload.read) }
        return path_file
      end 
  
 
      def is_boolean(column)
        return column.type.to_s=="string" && column.limit==1 && ["Y","N"].include?(column.default)
      end

      def get_list(model_name,sort,conditions={},params={})
         
         
         
        if self.respond_to?("get_list_dynamic_#{model_name.underscore}")
          list = self.send("get_list_dynamic_#{model_name.underscore}",params)
        else
          list = model_name.constantize
        end
      
        return list.blank? ? [] : list.all(:conditions => conditions,:order => sort)
      end

    end     
    
    module InstanceMethods  

      def validate_dynamic
#        method to overwrite
      end

      def read_only_assign        
          self.read_only = 'N' if self.respond_to?("read_only") 
      end

      def upper_case_dynamic
        self.class.columns_setup.each do |column|
          self[column[:name]].upcase! if column[:upper_case] && !self[column[:name]].nil?
        end
      end   

      def manage_dynamic_default(action='create')

        self.class.setup_model[:fixed_attributes].each do |name,value|
          if !self.send("#{name}_changed?") && !["id","created_at","updated_at"].include?(name) 
            if action=='create' || (action=='update' && self[name].nil?)
              self[name] = value 
            end
          end
        end
        
        self.class.columns_setup.each do |column|
          if !self.send("#{column[:name]}_changed?") && !["id","created_at","updated_at"].include?(column[:name]) && !column[:default_value].nil? 
            if action=='create' || (action=='update' && self[column[:name]].nil?)
              self[column[:name]] = column[:default_value] 
            end
          end
        end
      end
      
      
      
      
    end
  
  end
    
end
