# encoding: UTF-8

class EsAbility < ActiveRecord::Base

  has_and_belongs_to_many :es_roles    
  acts_as_dynamic_model([{:name => "action",
                          :type => "list_free",
                          :mandatory => true},
                         {:name => "controller",
                          :type => "list_free",
                          :field_key => true,
                          :field_key_scope => "action",
                          :mandatory => true},
                         {:name => "description",
                          :type => "text"}
                      ])
  
end