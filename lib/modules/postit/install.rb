class InstallPostit
  
  def self.install_postit
    DynWorkflowType.set_table_name("es_workflow_types") 
    DynWorkflow.set_table_name("es_workflows") 
    DynWorkflowStatus.set_table_name("es_workflow_statuses") 
    
    create_or_update_status('postit_draft','Draft')
    create_or_update_status('postit_analysis','Analysis')
    create_or_update_status('postit_dev','Development')
    create_or_update_status('postit_test','Test')
    create_or_update_status('postit_prod','Production')
    create_or_update_status('postit_cancel','Cancelled')
    create_or_update_status('postit_close','Closed')

    create_or_update_type('postit_process_it_dev','IT processus project')
    create_or_update_type('postit_process_it_hd','IT processus helpdesk')
    
    DynWorkflow.create_workflow({ :postit_draft     => [:postit_analysis, :postit_cancel],
                                  :postit_analysis  => [:postit_dev     , :postit_cancel],
                                  :postit_dev       => [:postit_test    , :postit_cancel],
                                  :postit_test      => [:postit_prod    , :postit_cancel],
                                  :postit_prod      => [:postit_close   , :postit_cancel]
                                },"postit_process_it_dev")
      
    DynWorkflow.create_workflow({ :postit_dev       => [:postit_test    , :postit_cancel],
                                  :postit_test      => [:postit_prod    , :postit_cancel],
                                  :postit_prod      => [:postit_close   , :postit_cancel]
                                },"postit_process_it_hd")
      
  end  
  
private  

  def self.create_or_update_status(status_name,label)
    s = DynWorkflowStatus.find_by_status_name(status_name)
    unless s
      s = DynWorkflowStatus.create({:status_name => status_name, :label => label})
    else
      s.update_attribute('label',label)
    end
  end

  def self.create_or_update_type(code,label)
    t = DynWorkflowType.find_by_code(code)
    unless t
      t = DynWorkflowType.create({:code => code, :label => label}) 
    else
      t.update_attribute('label',label)
    end
  end

end

InstallPostit.install_postit