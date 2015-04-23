# encoding: UTF-8

class EsContentDetailElementVideo < ActiveRecord::Base
  set_table_name "es_content_detail_elements" 
  
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  
end