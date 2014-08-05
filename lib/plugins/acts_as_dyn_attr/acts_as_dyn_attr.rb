# encoding: UTF-8

########################################## 
#          DYNamic ATTRibute             # 
######################################################################################### 
# help : Model.help_dyn_attr!                                                           #  
# ex:                                                                                   # 
#     Model.delete_attributes(:all)                                                     # 
#     Model.define_attributes([{:name =>'prenom'},                                      # 
#                              {:name =>'date_premier_job',:type_data=>'date'},         # 
#                              {:name => 'heure_pause',:type_data=>'time'},             # 
#                              {:name => 'salaire',:type_data=>'decimal',:length=>10},  # 
#                              {:name => 'naissance',:type_data=>'datetime'},           # 
#                              {:name => 'actif',:type_data=>'boolean'}])               # 
######################################################################################### 



class DynAttributeType < ActiveRecord::Base 
  has_many :dyn_attributes, :class_name => "DynAttribute", :foreign_key => "dyn_attribute_type_id" 
  attr_accessible :name, :attribute_type, :type_data, :mandatory, :default_value, :comments, :length, :decimal_nbr, :choices, :order_seq

  
  
end 
class DynAttribute < ActiveRecord::Base 
  belongs_to :dyn_attribute_type, :foreign_key => "dyn_attribute_type_id", :class_name => "DynAttributeType" 
  belongs_to :attributable, :polymorphic => true 
  attr_accessible :attributable_id, :attributable_type, :dyn_attribute_type_id, :value, :created_at, :created_by, :updated_at, :updated_by

  
  stampable if self.respond_to?("stampable") 
end 
  

module ActsAsDynAttr 
  module AddActAsMethods 
    
    
    def self.included(base) 
       base.extend(AddActAsMethods) 
    end 
  
  
    def has_dyn_attr(options = {}) 
      puts "\n" + "'has_dyn_attr' a été implémenté dans le model '%{model_name}'. Pour plus d'information, utilisez '%{model_name}.help_dyn_attr!'.".trn(:model_name => self.name) + "\n\n"

      cattr_accessor :table_name_attribute_type 
      cattr_accessor :table_name_attribute 
      self.table_name_attribute_type = options[:table_attribute_type] || 'dyn_attribute_types' 
      self.table_name_attribute      = options[:table_attribute]      || 'dyn_attributes' 
      return unless can_have_dyn_attr? 
      
      has_many :dyn_attributes, :as => :attributable 
      
      DynAttributeType.set_table_name(self.table_name_attribute_type) 
      DynAttribute.set_table_name(self.table_name_attribute) 
      
      
      cattr_accessor :dynamic_attribute_list 
      cattr_accessor :dynamic_attribute_details 
      self.dynamic_attribute_list     = [] 
      self.dynamic_attribute_details  = {} 
      include DynAttr 
      define_attributes(options[:attrs]) if options[:attrs] && options[:attrs].is_a?(Array) 
      
      attr_from_db=[] 
      DynAttributeType.find(:all,:conditions => ["attribute_type = ?",self.name], :order => 'order_seq').each do |attr| 

        attr_from_db << {:name => attr.name,:type_data => attr.type_data, :mandatory => attr.mandatory, :default_value => attr.default_value, :comments => attr.comments, :length => attr.length, :decimal_nbr => attr.decimal_nbr, :choices => attr.choices, :order_seq => attr.order_seq}

  
      end 
      define_attributes(attr_from_db) unless attr_from_db.blank? 
      
      validate :validate_dynamic_attributes 
  
      if self.respond_to?('before_validation_on_create') 
        before_validation_on_create :manage_dynamic_attributes_default #rails 2 
      else 
        before_validation :manage_dynamic_attributes_default, :on => :create    #rails 3 
      end 
      
      after_initialize :get_dynamic_attributes_from_db if self.respond_to?('after_initialize') #rails 3 
      after_save :dynamic_attributes_save_to_db 
  
    end 
    
    def can_have_dyn_attr? 
      return (ActiveRecord::Base.connection.table_exists? self.table_name_attribute_type  and ActiveRecord::Base.connection.table_exists? self.table_name_attribute)    

    end 
  
  end 
  
  ActiveRecord::Base.send(:include, AddActAsMethods) 
  
end 
  

module DynAttr 
  def self.included(base) 
    base.send :extend , ClassMethods 
    base.send :include, InstanceMethods 
  end 
  
  module ClassMethods  
  
#    def initialize(attributes = nil) 
#      tmp_dynamic_attributes = {} 
#      (attributes ||= {}).each{|att,value| tmp_dynamic_attributes[att] = value if self.dynamic_attribute_list.include?(att.to_s) }

#  
#      super(attributes.except(*tmp_dynamic_attributes.keys))   
#      set_dynamic_attributes(tmp_dynamic_attributes) 
#    end 
  
  
    def define_attributes(attrs=[]) 
      errors_define = [] 
      attrs.each do |attr| 
        error_define = validate_attribute_type(attr) 
        if error_define.blank? 
          unless dynamic_attribute_list.include?(attr[:name]) 
            dynamic_attribute_list << attr[:name]  
            define_method("#{attr[:name]}=") do |val| 
                write_attribute("#{attr[:name]}",val) 
            end 
            define_method("#{attr[:name]}") do 
                return read_attribute("#{attr[:name]}") 
            end 
            singleton_class.send(:define_method, "find_by_#{attr[:name]}") do |val| 
                e = self.find(:all, 
                              :conditions => ["#{self.table_name_attribute}.attributable_type = ? AND #{self.table_name_attribute_type}.name = ? AND #{self.table_name_attribute}.value = ?",self.name, attr[:name],val],

                              :include => [:dyn_attributes => :dyn_attribute_type]) 
                return e.blank? ? nil : e.first 
            end 
          end          
          create_db_attribute_type(attr) 
          attr_accessible attr[:name].to_sym 
          dynamic_attribute_details[attr[:name].to_sym]=attr.except([:name,:order_seq]) 
        else 
          errors_define.push *(error_define.map{|err| "nom '%{attr_name}'".trn(:attr_name =>attr[:name]) + " : #{err}"}) 
        end 
      end 
      return errors_define 
    end      
    
  
    def delete_attributes(attrs_name=[]) 
      attrs_name=dynamic_attribute_list.clone if attrs_name==:all 
      attrs_name.each do |attr_name| 
        attr_name = attr_name.to_s 
        if dynamic_attribute_list.include?(attr_name) 
          remove_method("#{attr_name}=") 
          remove_method("#{attr_name}") 
          singleton_class.send(:remove_method, "find_by_#{attr_name}") 
          delete_db_attribute_type(attr_name) 
          dynamic_attribute_list.delete(attr_name) 
          dynamic_attribute_details.delete(attr_name.to_sym) 
        end 
      end if attrs_name.is_a?(Array) 
    end 
    
    def inspect 
      txt = super 
      txt = (txt[0..-2] + ", " + dynamic_attribute_list.map{|attr| "#{attr}: #{self.dynamic_attribute_details[attr.to_sym][:type_data]}"}.join(', ') + txt[-1..-1] ) unless dynamic_attribute_list.blank?

  
      return txt 
    end 
  
    #define this method to get singleton class 
    def singleton_class 
      class << self 
        self 
      end 
    end  
    
    def help_dyn_attr 
      help = [ 
      "  ", 
      "  ", 
      "======================", 
      "= Dynamic attributes =", 
      "======================", 
      "  ", 
      "  ", 
      "The goal is to declare new attribute as field table without change the table structure", 
      "You need two tables :", 
      "  - DYN_ATTRIBUTE_TYPES : 'id' 'name' 'attribute_type' 'type_data' 'mandatory' 'default_value'", 
      "                          'comments' 'length' 'decimal_nbr' 'choices' 'order_seq'", 
      "     Each dynamic attribute created to a model must have a record into the table DYN_ATTRIBUTE_TYPES", 
      "  - DYN_ATTRIBUTES      : 'id' 'attributable_id' 'attributable_type' 'dyn_attribute_type_id'", 
      "                          'value' 'created_at' 'created_by' 'updated_at' 'updated_by'", 
      "     Each model instance having dynamics attributes must have records into the table DYN_ATTRIBUTE", 
      "  the table name can be changed using options :table_attribute_type or :table_attribute", 
      "  ", 
      "  ", 
      "You may handle this plugin by adding 'has_dyn_attr' into a model", 
      "  has_dyn_attr options", 
      "    - :table_attribute_type : table name for dynamic attribute type", 
      "    - :table_attribute      : table name for dynamic attribute", 
      "    - :attrs                : contain dynamic attributes to create", 
      "       Structure of :attrs", 
      "        :name          : Name of dynamic attribute", 
      "        :type_data     : Type of data (string,integer,decimal,date,datetime,time,boolean)", 
      "        :mandatory     : Attribute mandatory 'Y' or 'N'", 
      "        :default_value : Default value", 
      "        :comments      : Comment", 
      "        :length        : Max length of value", 
      "        :decimal_nbr   : Number of decimal for 'decimal' type", 
      "        :choices       : list of valid values", 
      "  ", 
      "  ", 
      "  Class attributes", 
      "    - table_name_attribute_type : Model.table_name_attribute_type", 
      "                                  Table name of dynamic attribute types", 
      "    - table_name_attribute      : Model.table_name_attribute", 
      "                                  Table name of dynamic attributes", 
      "    - dynamic_attribute_list    : Model.dynamic_attribute_list", 
      "                                  List of dynamic attributes name", 
      "    - dynamic_attribute_details : Model.dynamic_attribute_details", 
      "                                  List of details for dynamic attributes", 
      "  ", 
      "  Class methods", 
      "    - help_dyn_attr     : Model.help_dyn_attr", 
      "                          Get help for dynamic attributes plugin. Receive it in an array of lines", 
      "    - define_attributes : Model.define_attributes([{:name => 'prenom', :length => 50, :type_data => 'string'},{:name => 'age', :length => 3, :type_data => 'integer'}])",

      "                          Create new dynamic attributes", 
      "    - delete_attributes : Model.delete_attributes(['prenom','age'])", 
      "                          Delete dynamic attributes", 
      "  ", 
      "  Instance methods", 
      "    - dyn_errors            : instance.dyn_errors", 
      "                              get the list of instance error", 
      "    - dyn_attributes_value  : instance.dyn_attributes_value", 
      "                              Return a hash with each dynamic attribute values", 
      "    - dyn_attributes_detail : instance.dyn_attributes_detail", 
      "                              Return a hash with each dynamic attribute details (and values)", 
      ]      
      return help 
    end 

    def help_dyn_attr! 
      self.help_dyn_attr.each do |line| 
        puts line 
      end 
      return nil 
    end 
    
private 
  
    def validate_attribute_type(attr={}) 
      error_message = [] 
      if attr.is_a?(Hash) 
        if !attr[:name].nil? && attr[:name].is_a?(String) 
          attr[:type_data] ||= 'string' 
          case attr[:type_data] 
            when 'string' 
              attr[:length] ||= 50 
              attr[:decimal_nbr]  = nil 
            when 'integer' 
              attr[:length] ||= 10 
              attr[:decimal_nbr]  = nil 
            when 'decimal'  
              attr[:length] ||= 10 
              attr[:decimal_nbr]||= 2 
            when 'date'  
              attr[:length]   = 10 
              attr[:decimal_nbr]  = nil 
            when 'datetime'  
              attr[:length]   = 19 
              attr[:decimal_nbr]  = nil 
            when 'time'  
              attr[:length]   = 8 
              attr[:decimal_nbr]  = nil 
            when 'boolean'  
              attr[:length]   = 1 
              attr[:decimal_nbr]  = nil 
              attr[:choices]  = 'N,Y' 
              attr[:default_value]  ||= 'N' 
            else 
              error_message << "Type de donnée '%{type_date}' invalide".trn(:type_date =>attr[:type_data]) 
              attr[:length]   = 0 
          end 
          unless is_integer(attr[:length]) 
            error_message << "Longueur de donnée '%{length}' invalide".trn(:length =>attr[:length]) 
          else 
            attr[:length] = attr[:length].to_i 
          end 
          unless attr[:decimal_nbr].nil? 
            unless is_integer(attr[:decimal_nbr]) 
              error_message << "Nombre de décimales '%{decimal_nbr}' invalide".trn(:decimal_nbr =>attr[:decimal_nbr]) 
            else 
              attr[:decimal_nbr] = attr[:decimal_nbr].to_i 
            end            
          end          
        else 
          error_message << "Le nom est obligatoire".trn 
        end 
      else 
        error_message << "'%{attr}' n'est pas de type Hash".trn(:attr => attr)
      end 
      return error_message 
    end 

    def is_integer(value) 
        is_number = value.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true 
        return (is_number && value.to_i == value.to_f) 
    end 
  
  
    def create_db_attribute_type(attr_hsh) 
      unless attr_hsh[:name].blank? 
        attr_hsh[:attribute_type] = self.name 
        attr_hsh.delete(:order_seq) 
        attr = DynAttributeType.first(:conditions => ["name = ? and attribute_type = ?",attr_hsh[:name],self.name]) 
        if attr.blank? 
          attr_last = DynAttributeType.first(:conditions => ["attribute_type = ?",self.name], :order => 'order_seq DESC')

  
          attr_hsh[:order_seq] = attr_last.blank? ? 1 : attr_last.order_seq + 1 
          attr = DynAttributeType.new(attr_hsh) 
        else 
          attr.attributes = attr_hsh 
        end 
        attr.save! 
      end 
    end      
  
    def delete_db_attribute_type(attr_name) 
      attr = DynAttributeType.first(:conditions => ["name = ? and attribute_type = ?",attr_name,self.name]) 
      unless attr.blank? 
        attr.dyn_attributes.destroy_all 
        attr.destroy 
      end 
    end      
  
  end 
  
  module InstanceMethods 
    def inspect 
      txt = super 
      txt = (txt[0..-2] + ", " + dynamic_attribute_list.map{|attr| "#{attr}: #{self[attr.to_sym].inspect}"}.join(', ') + txt[-1..-1] ) unless dynamic_attribute_list.blank?

  
      return txt 
    end 
    
#    def set_dynamic_attributes(attributes = {}) 
#      return if attributes.blank? 
#      attributes.each do |att, value| 
#        if self.class.dynamic_attribute_list.include?(att.to_s) 
#          attributes.delete(att)          
#          send(att.to_s + '=', value) 
#        end        
#      end      
#    end 
    
    def after_initialize 
      get_dynamic_attributes_from_db 
    end 
  
    
  
    def dyn_errors 
      self.errors.full_messages 
    end 
  
    def manage_dynamic_attributes_default 
      self.class.dynamic_attribute_list.each do |attr_name| 
        tmp_name = attr_name.to_sym 
        tmp_attr_type  = self.class.dynamic_attribute_details[attr_name.to_sym] 
        self[tmp_name] = tmp_attr_type[:default_value] if !tmp_attr_type[:default_value].nil? && self[tmp_name].blank? 
      end      
    end 
  
    def validate_dynamic_attributes 
      self.class.dynamic_attribute_list.each do |attr_name| 
        tmp_name = attr_name.to_sym 
        tmp_value = self[tmp_name] 
        tmp_attr_type  = self.class.dynamic_attribute_details[attr_name.to_sym] 
        errors.add(tmp_name,"est obligatoire".trn) if tmp_attr_type[:mandatory]=='Y' && tmp_value.blank? 
        txt_type =  tmp_attr_type[:type_data] 
        txt_type += tmp_attr_type[:type_data] == 'decimal' ? " (#{tmp_attr_type[:length]},#{tmp_attr_type[:decimal_nbr]}})" : " (#{tmp_attr_type[:length]})" 

  
        errors.add(tmp_name," n'est pas un type de donnée '%{txt_type}'".trn(:txt_type =>txt_type)) if !tmp_value.nil? && !is_valid_value_for_type?(tmp_value.to_s,tmp_attr_type[:type_data],tmp_attr_type[:length],tmp_attr_type[:decimal_nbr])

  
        choices_list = tmp_attr_type[:choices].split(',').map{|e| "'#{e}'"}.join(',')  
        errors.add(tmp_name,"n'est pas valide.'%{value}' n'est pas dans la liste %{value_list}".trn(:value=> tmp_value,:value_list =>choices_list)) if !tmp_attr_type[:choices].nil? && !tmp_attr_type[:choices].split(',').include?(tmp_value)

           
      end 
  
    end 
  
    def dyn_attributes_value 
      hash_dyn_attributes={} 
      self.class.dynamic_attribute_details.each do |attr_name,hash_detail| 
        hash_dyn_attributes[attr_name]=self[attr_name] 
      end 
      return hash_dyn_attributes 
    end 
  
    def dyn_attributes_detail 
      hash_dyn_attributes={} 
      self.class.dynamic_attribute_details.each do |attr_name,hash_detail| 
        hash_dyn_attributes[attr_name]=hash_detail 
        hash_dyn_attributes[attr_name][:value]=self[attr_name] 
      end 
      return hash_dyn_attributes 
    end 
  
private 
    
    def is_valid_value_for_type?(value, type_data, length, decimal_nbr) 
      if value.length <= (length||0) 
        is_number = value.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true 
        case type_data 
          when 'integer' 
            error_type  = !((is_number && value.to_i == value.to_f) || value.blank?) 
          when 'decimal' 
            value_array       = value.split('.') 
            error_type  = !( (is_number && (value_array.length < 2 || value_array[1].length <= decimal_nbr)) || value.blank?)

          when 'string' 
            error_type = false 
          when 'date' 
            error_type  = !valid_date?('date',value) 
          when 'datetime' 
            error_type  = !valid_date?('datetime',value) 
          when 'time' 
            error_type  = !valid_date?('time',value) 
          when 'boolean' 
            error_type  = !(['N','Y'].include?(value) || value.blank?) 
          else 
            error_type = true 
        end 
      else 
        error_type = true 
      end 
      return !error_type  
    end 
    
    def valid_date?(type,value) 
      begin 
        Date.strptime(value.to_s, '%d/%m/%Y') if type=='date' 
        DateTime.strptime(value.to_s, '%d/%m/%Y %I:%M:%S') if type=='datetime' 
        DateTime.strptime(value.to_s, '%I:%M:%S') if type=='time' 
        return true 
      rescue ArgumentError 
        return false 
      end 
    end 

    
    
    def get_dynamic_attributes_from_db 
      self.dyn_attributes.each do |dyn_attr| 
        if !dyn_attr.dyn_attribute_type.blank? && self.class.dynamic_attribute_list.include?(dyn_attr.dyn_attribute_type.name)

  
          self[dyn_attr.dyn_attribute_type.name.to_sym]=dyn_attr.value 
        end 
      end 
    end 
  
    def dynamic_attributes_save_to_db 
      self.attributes.each do |attr_name,attr_value| 
        if self.class.dynamic_attribute_list.include?(attr_name) 
          attr_type = DynAttributeType.first(:conditions => ["name = ? and attribute_type = ?",attr_name,self.class.name])

  
          unless attr_type.blank? 
            tmp_dyn_attr = self.dyn_attributes.find(:first,:conditions => ["dyn_attribute_type_id = ?",attr_type.id]) 
            if tmp_dyn_attr.blank? 
              tmp_dyn_attr = DynAttribute.new({:value => attr_value,:dyn_attribute_type_id => attr_type.id}) 
              self.dyn_attributes << tmp_dyn_attr 
            else 
              tmp_dyn_attr.update_attribute('value',attr_value) 
            end 
          end          
        end        
      end 
    end 
  end  
  
end 

