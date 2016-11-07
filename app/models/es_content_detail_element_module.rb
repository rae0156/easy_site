# encoding: UTF-8

class EsContentDetailElementModule < ActiveRecord::Base
  set_table_name "es_content_detail_elements" 
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  

  #appelé par l'attribut dynamique 'module_action_name' de type LIST
  #def self.get_modules
  #  return EsModule.get_module_action_list_choice
  #end


end