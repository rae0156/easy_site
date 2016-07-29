# encoding: UTF-8 
module DynSetupModel 
  module AddActAsMethods 
    
    
    def self.included(base) 
      base.extend AddActAsMethods::ClassMethods 
      #baseinclude AddActAsMethods::InstanceMethods 
    end 
  
    module ClassMethods 
      def init_dynamic_model_from_setup(columns_setup) 
        return columns_setup if !DynamicModelSetup.find_by_model_name(self.name) || !EsModule.activated("dyn_model_setup")
        puts "Initialisation du setup pour le modèle #{self.name}"
        init_default_setup_db(columns_setup)
        return get_from_setup_db(columns_setup)
      end 

      def reinit_dynamic_model_from_setup
        init_setup(self.columns_setup,self.setup_model) if self.respond_to?('init_setup')
        dynamic_validation if self.respond_to?('dynamic_validation')
      end
      
      private
      
      def init_default_setup_db(columns_setup)
        dyn_model_setup = DynamicModelSetup.find_by_model_name(self.name)
        dyn_att_list   = DynamicModelFieldSetup.dynamic_attribute_list
        dyn_attrs = DynAttributeType.where(:attribute_type => "DynamicModelFieldSetup")

        columns_setup.each do |col|
          field_setup = dyn_model_setup.dynamic_model_field_setups.where(:field_name => col[:name]).first
          if field_setup && field_setup.dyn_attributes.count == 0
            puts "Paramétrage dynamique : Modèle #{dyn_model_setup.model_name} - Champs #{field_setup.field_name}"
            tmp_attributes = {}
            col.each do |attr,value|
              if dyn_att_list.include?(attr.to_s)
                dyn_attr = dyn_attrs.where(:name => attr.to_s).first
                if dyn_attr
                  if !value.blank?
                    tmp_attributes[attr] = (dyn_attr.type_data == "boolean") ? convert_boolean_to_YN(value) : value
                  elsif dyn_attr && !dyn_attr.default_value.blank?
                    tmp_attributes[attr] = dyn_attr.default_value
                  end
                end
              end
            end 

            field_setup.update_attributes(tmp_attributes)
            if field_setup.errors.full_messages.count > 0
              puts "Erreur : #{tmp_attributes.inspect}"
              field_setup.errors.full_messages.each do |msg|
                puts "    - #{msg}"
              end
            end               
          end
        end
      end
      
      def get_from_setup_db(columns_setup)
        dyn_att_list   = DynamicModelFieldSetup.dynamic_attribute_list
        dyn_attrs = DynAttributeType.where(:attribute_type => "DynamicModelFieldSetup")
        dyn_model_setup = DynamicModelSetup.find_by_model_name(self.name)
        columns_setup.each do |col|
          field_setup = dyn_model_setup.dynamic_model_field_setups.where(:field_name => col[:name]).first
          if field_setup && field_setup.dyn_attributes.count > 0
            dyn_attrs.each do |dyn_attr|
              if col.has_key?(dyn_attr[:name].to_sym) && dyn_att_list.include?(dyn_attr[:name])
                case dyn_attr.type_data
                when "boolean"
                  value = convert_YN_to_boolean(field_setup[dyn_attr[:name].to_sym])
                when "integer"
                  value = (field_setup[dyn_attr[:name].to_sym]||0).to_i
                else
                  value = field_setup[dyn_attr[:name].to_sym]
                end
                col[dyn_attr[:name].to_sym] = value
              end
            end
          end
        end
        
        return columns_setup
      end
      
      def convert_boolean_to_YN(value)
        value ? "Y" : "N"
      end
      def convert_YN_to_boolean(value)
        value == "Y"
      end
      
      
    end 
  
  
  end 

end 

ActiveRecord::Base.send(:include, DynSetupModel::AddActAsMethods) 

