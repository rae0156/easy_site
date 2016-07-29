# encoding: UTF-8

class InstallResourceSetup
  

  def self.install_setup
    create_setup('ressource_suppression_action','choice','resource/paramétrage','supprimer|désactiver','désactiver','N')
    create_setup('ressource_init_statut','text','resource/paramétrage',nil,'','N')
    create_setup('ressource_init_priorite_action','text','resource/paramétrage',nil,'','N')
    create_setup('ressource_init_priorite_ressource','text','resource/paramétrage',nil,'','N')
    create_setup('ressource_init_quand_action','text','resource/paramétrage',nil,'','N')
    create_setup('ressource_init_pour_quand_action','text','resource/paramétrage',nil,'','N')
    create_setup('ressource_init_quand_ressource','text','resource/paramétrage',nil,'','N')
    create_setup('ressource_init_pour_quand_ressource','text','resource/paramétrage',nil,'','N')
  end  
  
private  

  def self.create_setup(name,type_data,path,possible_values,value,read_only)
    s = EsSetup.find_by_name(name)
    unless s
      s = EsSetup.create({:name => name, :type_data => type_data,:path => path,:possible_values => possible_values,:value => value,:read_only => read_only})
    end
  end

end

InstallResourceSetup.install_setup