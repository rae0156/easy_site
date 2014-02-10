unless File.basename($0) == "rake" 
  
  directory = File.join(Rails.root,'lib','plugins','tactilog') #File.dirname(__FILE__) 
  #copy view and controller
  ['/views', '/views/debugs', '/controllers',['/stylesheets','/public/stylesheets']].each do |dir|
    if dir.is_a?(Array)
      source = File.join(directory,dir[0])
      dest = File.join(Rails.root,dir[1])
    else
      source = File.join(directory,dir)
      dest = File.join(Rails.root,'app',dir)
    end
    
    FileUtils.mkdir_p(dest)  
    Dir.glob(source+'/*.*').each do |filename|
      unless File.exists?(File.join(dest,File.basename(filename).gsub('rhtml','html.erb') ))
        FileUtils.cp(filename, File.join(dest,File.basename(filename).gsub('rhtml','html.erb') ))
      end
    end
  end
  
  
  
  #add load plugin
  Dir.glob(File.join(Rails.root,'lib','plugins','tactilog','lib') + "/*.rb").each do |file| 
    require file 
  end

end
