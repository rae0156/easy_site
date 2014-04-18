class DataFile < ActiveRecord::Base
  require 'fileutils'

  def self.create_dir(*tmp_dirs)    
    tmp_dirs = File.join(Rails.root,tmp_dirs)
    FileUtils.mkdir_p(tmp_dirs)
  end      

  def self.remove_file(file_name)
    File.delete(file_name)
  end


  def self.save(upload,directory)
    name =  upload['datafile'].original_filename
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
  end
end