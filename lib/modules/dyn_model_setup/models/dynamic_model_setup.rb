# encoding: UTF-8

class DynamicModelSetup < ActiveRecord::Base
  has_es_interface_models
  attr_accessible :model_name, :label, :read_only

  has_many :dynamic_model_field_setups  
  
  def self.get_menu_list
    menus = []
    self.order('model_name').all.each do |dms|
      menus << ["Paramétrer la gestion des '%{label}'".trn(:label =>dms.label.downcase), {:controller => 'dynamic_model_setups', :action => 'setup_a_model' , :id => dms.id},dms.model_name]
    end
    return menus 
  end
  
  def reinit_dynamic_model_from_setup
    if class_exists?(self.model_name)
      model = self.model_name.classify.constantize
      model.reinit_dynamic_model_from_setup if model.respond_to?('reinit_dynamic_model_from_setup')
    end    
  end
  
  def reinit_model
    reload = false
    self.dynamic_model_field_setups.each do |f|
      f.dyn_attributes.destroy_all
    end

    #reload model
    if class_exists?(self.model_name)
      model = self.model_name.classify.constantize
      file_name = ActiveSupport::Dependencies.search_for_file(self.model_name.classify.underscore)
      unless file_name.blank? #on recharge uniquement si on a le nom de fichier du model
        Object.send(:remove_const, self.model_name.classify.to_sym)
        load file_name
        Object.const_get(self.model_name.classify.to_sym)
        reload = true
      end
    end    

    begin
      model = self.model_name.classify.constantize
    rescue 
    end
    
    return reload
  end
  
  
  def get_dynamic_model_setup
    read_only = self.read_only=="Y"

    if class_exists?(self.model_name)
      model = self.model_name.classify.constantize
      model #init model if not yet
    end

    attrs = DynamicModelFieldSetup.dynamic_attribute_details

    cat_attr = {}
    attrs.each do |at|
      cat = at[1][:category]
      cat_attr[cat] = [] unless cat_attr[cat].present?
      cat_attr[cat] << at[1] 
    end

    tabs = []
    self.dynamic_model_field_setups.each do |field_dyn|
      tab = {}
      tab[:title]="Colonne %{col}".trn(:col => field_dyn.field_name)
      i=0
      cat_attr.each do |cat,fields|
        i+=1
        tab["title_#{i}".to_sym]=cat.split("/").last.gsub("_", " ").humanize
        tab["group_#{i}".to_sym]=[]
        fields.each do |f|
          element =  {:name          => field_dyn.field_name + "_" + f[:name],
                      :format        => f[:type_data],
                      :value         => field_dyn[f[:name]],
                      :description   => f[:comments],
                      :read_only     => (read_only || (f[:read_only]=="Y")) ? "Y" : "N", 
                      :mandatory     => f[:mandatory]
                      }
          tab["group_#{i}".to_sym] << element
        end
      end
      
      tabs << tab
    end

    return tabs
  end
  
end