class InstallDir
  
  def self.install_dir
    
    create_or_update_local_path('Public','public')
    create_or_update_local_path('Log','log')
    create_or_update_local_path('Appli','.')
    
  end  
  
private  

  def self.create_or_update_local_path(name,local_path)
    p = DirBase.find_by_name(name)
    unless p
      p = DirBase.create({:name => name, :local_path => local_path, :description => name})
    else
      p.update_attribute('local_path',local_path)
    end
  end


end

InstallDir.install_dir