# encoding: UTF-8

class DirContent
  
  def initialize(root, typefile)
    @root = root
    @typefile = typefile
  end

  def get_dirs(path=".", with_detail=false)
    path = "" if path.nil?
    @path = File.join(File.expand_path(@root), path)
    @dirs = []
    if File.exists?(@path)
      if with_detail
        unless path.blank?
          stat = File.stat(@path)
          tmp_dir = @path.split('/')[0..-2].join('/')
          @dirs << ['..',stat.mtime,tmp_dir[@root.size+1..-1]]
        end
        Dir.entries(@path).each do |dir|
          tmp_dir = File.join(@path,dir)
          if File.directory?(tmp_dir) && dir[0,1]!="." && (@typefile.split(',').include?('*') || @typefile.split(',').include?('[DIR]'))
            stat = File.stat(tmp_dir)
            @dirs << [dir,stat.mtime,tmp_dir[@root.size+1..-1]]
          end
        end
      else
        Dir.entries(@path).each do |dir|
          if File.directory?(File.join(@path, dir)) && dir[0,1]!="." && (@typefile.split(',').include?('*') || @typefile.split(',').include?('[DIR]'))
            @dirs << dir
          end
        end
      end
    end
    @dirs
  end

  def get_files(path=".", with_detail=false)
    path = "" if path.nil?
    @path = File.join(File.expand_path(@root), path)
    @files = []
    
    if File.exists?(@path)
      if with_detail
        @typefile.split(',').each do |filter|
          unless ['[DIR]','*'].include?(filter)
            Dir.glob(File.join(@path, filter)).each do |file|
              if File.file?(file)
                stat = File.stat(file)
                @files << [File.basename(file),stat.size,stat.mtime]
              end
            end
          end
        end
      else
        Dir.entries(@path).each do |file|
          if File.file?(File.join(@path, file)) && (@typefile.split(',').include?('*') || @typefile.split(',').include?(File.extname(file).gsub(".","")))
            @files << file
          end
        end
      end
    end
    @files
  end

  def get_content(path=".")
    if File.expand_path(File.join(@root,path)).starts_with?(@root)
      [get_dirs(path,true), get_files(path,true)]
    else
      [[],[]]
    end
  end
  
  
  def get_content_upload(path=".")
      [get_dirs(path,false), get_files(path,false)]
  end

  def get_dir_tree_html(path,first=true)
    txt =[]
    tmp_dirs=get_dirs(path,false)
    #return txt if tmp_dirs.blank?
    txt << (first ? '<UL id="tree_view_file" class="filetree" style="display: none;">' : '<UL>')
    if first
      txt << "<LI><span class='folder'>"
      txt << ['..','']
      txt << "</span>"      
      txt = txt + get_dir_tree_html(path,false)
      txt << "</LI>"
    else
      tmp_dirs.each do |d|
        txt << "<LI><span class='folder'>"
        sub_dir = path + (path.blank? ? '' : '/') + d 
        txt << [d,sub_dir]
        txt << "</span>"      
        txt = txt + get_dir_tree_html(sub_dir,false)
        txt << "</LI>"
      end
    end
    txt << "</UL>"
    txt
  end


  def self.get_sound_for_site
    setup_dir_musique = EsSetup.get_setup("répertoire_musique","public/")
    content = DirContent.new(setup_dir_musique,"mp3,ogg,wav")
    files = content.get_files.map{|f| f[0..-5] }
    files.uniq.sort
  end
    
end
