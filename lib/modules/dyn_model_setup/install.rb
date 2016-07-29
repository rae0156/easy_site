# encoding: UTF-8

class InstallDynModel
  
  def self.install_dyn_model
    create_dyn_model_setup('EsTest','Modèle de test','N')
    init_dynamic_attributes(File.join(File.dirname(__FILE__),"initializers","dynamic_model_attributes.yml"))
  end  

end

InstallDynModel.install_dyn_model