# encoding: UTF-8 

  def create_dyn_model_setup(model_name,label,read_only='Y')
    m = DynamicModelSetup.find_by_model_name(model_name)
    unless m
      m = DynamicModelSetup.create({:model_name => model_name, :label => label, :read_only => read_only}) 
    else
      m.update_attributes(:label => label, :read_only => read_only)
    end
  end

