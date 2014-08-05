# encoding: UTF-8 

class EsPostit < ActiveRecord::Base

  has_es_interface_models



  #has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  
  acts_as_dynamic_model([{:name => "label",
                          :mandatory => true}
                      ])
                      
#has_workflow({:role_model_name => "EsRole", :user_model_name => "EsUser", :table_name_workflow_type => "es_workflow_types", :table_name_workflow => "es_workflows", :table_name_workflow_status => "es_workflow_statuses",:workflow_by_user => true})


  #EsPostit.test
#  def self.test    
#    
#    
#    tmp = {:step1 => [:step2, {:status_end => :step3, :check_user => 'Y'}],:step3 => [:step2, :closed]}
#    puts "ici : #{self.workflow_type}"
#    self.create_workflow(tmp,'toto')  
#
#    EsUser.current_user = EsUser.find(25)
#
#    wf = DynWorkflow.find(:first)
#    puts "ici : #{wf.id}"
#    puts "ici : #{wf.es_roles.inspect}"
#
#
#    puts "next status of 1 : #{DynWorkflow.get_next_statuses(1,1)}" 
#    puts "next status of 1 : #{DynWorkflow.get_next_statuses_name(1,1)}" 
#    
#    puts "first status : #{ DynWorkflow.get_first_status('toto').inspect}"
#    puts "first status : #{ DynWorkflow.get_first_status('toto').status_name}"
#    puts "last status : #{ DynWorkflow.get_last_statuses('toto').inspect}"
#    puts "last status : #{ DynWorkflow.get_last_statuses_name('toto').inspect}"
#   
#
#  end

end