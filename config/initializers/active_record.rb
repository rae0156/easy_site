class ActiveRecord::Base
  
  def self.get_export_file_name(options={}) 
    name = (options[:name].presence || "export.xls") 
    
    ex    = File.extname(name)   
    base  = File.basename(name, ex)    
    
    name  = base 
    name  += ("_" + Time.now.strftime('%Y%m%d%H%M%S')) if options[:prefix].presence == true    
    name  += ex 
    
    directory = options[:directory].presence || "export" 
    
    path = File.join('public', 'archives',directory) 
    
    create_dir(path)
    path_file = File.join(Rails.root , path, name) 
    return path_file 
  end 
  
end