# encoding: UTF-8

class InstallEndDynModel
  
  def self.install_end_dyn_model
    puts "========================================================="
    puts "= Initialisation de la table dynamic_model_field_setups ="
    puts "========================================================="
    model_loaded = false
    DynamicModelSetup.all.each do |dyn_model|
      if !model_loaded && !class_exists?(dyn_model.model_name) 
        Rails.application.eager_load! #charger les models si pas encore loadés
        model_loaded = true
      end
      if class_exists?(dyn_model.model_name)
        model = dyn_model.model_name.classify.constantize
        model.columns.each do |column|
          unless ["id"].include?(column.name)
            field = dyn_model.dynamic_model_field_setups.where(:field_name => column.name).first
            field = dyn_model.dynamic_model_field_setups << DynamicModelFieldSetup.create(:field_name => column.name) unless field
          end
        end  
      end
    end
  end  

end

InstallEndDynModel.install_end_dyn_model