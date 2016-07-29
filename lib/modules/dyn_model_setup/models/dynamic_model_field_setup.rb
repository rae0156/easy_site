# encoding: UTF-8

class DynamicModelFieldSetup < ActiveRecord::Base
  has_es_interface_models

  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  

  belongs_to :dynamic_model_setup  
  attr_accessible :field_name, :dynamic_model_setup_id
    
end