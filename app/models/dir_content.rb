class DirContent
  
  def initialize(root, typefile)
    @root = root
    @typefile = typefile
  end

  def get_dirs(path=".")
    path = "" if path.nil?
    @path = File.join(File.expand_path(@root), path)
    @dirs = []
    if File.exists?(@path)
      Dir.entries(@path).each do |dir|
        if File.directory?(File.join(@path, dir)) && dir[0,1]!="." && (@typefile.split(',').include?('*') || @typefile.split(',').include?('[DIR]'))
          @dirs << dir
        end
      end
    end
    @dirs
  end

  def get_files(path=".")
    path = "" if path.nil?
    @path = File.join(File.expand_path(@root), path)
    @files = []
    
    if File.exists?(@path)
      Dir.entries(@path).each do |file|
        if File.file?(File.join(@path, file)) && (@typefile.split(',').include?('*') || @typefile.split(',').include?(File.extname(file).gsub(".","")))
          @files << file
        end
      end
    end
    @files
  end

  def get_content(path=".")
      [get_dirs(path), get_files(path)]
  end
  
end
