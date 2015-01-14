# encoding: UTF-8 

class DirManager < ActiveRecord::Base

  has_es_interface_models
  acts_as_multi_site

  stampable
  has_many     :dir_accesses 
  belongs_to   :dir_base 

  attr_accessible :name, :description, :real_dir, :file_ext, :sub_dir_by_user, :dir_base_id, :limit_size

  validates_presence_of :name, :message => '#' + 'Le nom est obligatoire'.trn
  validates_presence_of :dir_base_id, :message => '#' + 'Le chemin de base est obligatoire'.trn
  validates_presence_of :real_dir, :message => '#' + 'Le nom du répertoire est obligatoire'.trn
  validates_presence_of :file_ext, :message => '#' + "L'exention de fichier est obligatoire".trn
  validates_uniqueness_of :name, :message => "#" + "Ce nom existe déjà".trn

  validate :validate_special
  before_destroy :check_dependances

  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Répertoires".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end

  def self.action_available?(dir_name,action="")
    dir = DirManager.find_by_name(dir_name)
    if dir
      return dir.action_available?(action)
    else
      return false
    end
  end

  def action_available?(action="")   
    right = true
    actions = action.is_a?(Array) ? action : [action]

    actions.each do |act|
      self.dir_accesses.each do |a|
        if a.all_role=='Y' 
          role_ok = true
        elsif !EsUser.current_user.blank? 
          role_ok = EsUser.current_user.role?(a.es_roles.map{|r|r.name})
        else
          role_ok = false
        end        
        
        if role_ok && (act.starts_with?('dir_') || act.starts_with?('file_')) && a.class.column_names.include?(act)
          right= (a[act]=='Y')
        else
          right=false
        end
        break unless right
      end
      break unless right
    end
    return right    
    
  end

  def validate_special
    
    
    
    tmp_real_dir = DirManager.sanitize_filename(self.real_dir,'/')
    tmp_file_ext = DirManager.sanitize_filename(self.file_ext,"*;.")


    
    
    if self.real_dir
      if !self.real_dir.index('.').nil?
        errors.add("real_dir","#" + "Un nom de répertoire ne peut pas contenir de '.'".trn)
      elsif self.real_dir != tmp_real_dir 
        errors.add("real_dir","#" + "Ce nom du répertoire n'est pas accepté".trn)
      elsif self.real_dir[0..0] =~ /[^A-Za-z]/
        errors.add("real_dir","#" + "Le nom du répertoire doit commencer par une lettre".trn)
      end    
    end
    
    if self.file_ext
      unless self.file_ext == tmp_file_ext 
        errors.add("file_ext","#" + "Cette extention de fichier n'est pas accepté".trn)
      end    
    end
    
  end

  def self.create_dir(path,new_dir)
    begin
        error=nil
        dir = File.join(path,new_dir||'')
        if File.directory?(dir)
          error="Le répertoire '%{dir}' existe déjà".trn(:dir => new_dir)
        else
          Dir.mkdir(dir)
        end
    rescue => ex
      error = "Erreur lors de la création du répertoire. Vérifier que le nom se compose de caractères acceptés.".trn
    end
    error
  end

  def self.delete_dir(path,new_dir)
    begin
        error=nil
        dir = File.join(path,new_dir||'')
        records = Dir.glob(dir+"/*")
        if File.directory?(dir)
          unless (records - ['..','.']).empty?
            error="Le répertoire '%{dir}' n'est pas vide".trn(:dir => new_dir)
          else
            Dir.rmdir(dir)
          end
        else
          error="Le répertoire '%{dir}' n'existe pas".trn(:dir => new_dir)
        end
    rescue => ex
      error = "Erreur lors de la suppression du répertoire.".trn
    end
    error
  end

  def self.delete_all_files(path)
    begin
        error=nil
        FileUtils.rm Dir.glob(File.join(path,'*.*'))
    rescue => ex
      error = "Erreur lors de la suppression du fichier.".trn
    end
    error
  end

  def self.delete_file(path,file_selected)
    begin
        error=nil
        file = File.join(path,file_selected||'')
        if File.file?(file)
          unless File.writable?(file)
            error="Le fichier '%{file}' ne peut pas être supprimé".trn(:file => file_selected)
          else
            File.delete(file)
          end
        else
          error="Le fichier '%{file}' n'existe pas".trn(:file => file_selected)
        end
    rescue => ex
      error = "Erreur lors de la suppression du fichier.".trn
    end
    error
  end

  def self.rename_dir(path,old_dir,new_dir)
    begin
        error=nil
        dir = File.join(path,new_dir||'')
        dir_old = File.join(path,old_dir||'')
        if File.directory?(dir)
          error="Le répertoire '%{dir}' existe déjà".trn(:dir => new_dir)
        elsif !File.directory?(dir_old)
          error="Le répertoire '%{dir}' n'existe pas".trn(:dir => old_dir)
        else
            File.rename(dir_old,dir)
        end
    rescue => ex
      error = "Erreur lors du changement de nom du répertoire. Vérifier que le nom se compose de caractères acceptés.".trn
    end
    error
  end

  def self.paste_file(path,from_file,action)
    error = ''
  
    if !File.file?(from_file)
        error="Le fichier '%{file}' n'existe plus".trn(:file => from_file)
    else
      from_file_name = File.basename(from_file)
      from_dir_name  = File.dirname(from_file)
      same_dir       = (from_dir_name==path)
      prefix         = ""
      while File.file?(File.join(path,prefix + from_file_name))
        prefix = prefix.blank? ? 'cp_' : "cp_#{(prefix[3..-1]||'0').gsub('_','').to_i + 1}_"       
      end
      to_file_name   = prefix + from_file_name
      
      begin
        if action=='cut'
          FileUtils.mv(from_file,File.join(path,to_file_name))
        elsif action=='copy'
          FileUtils.cp(from_file,File.join(path,to_file_name))
        end
      rescue => ex
        error = "Erreur lors de la copie ou du déplacement du fichier.".trn
      end
      
    end
  
    error
  end

  def self.rename_file(path,old_file,new_file)
    begin
        error=nil
        file = File.join(path,new_file||'')
        file_old = File.join(path,old_file||'')
        if File.file?(file)
          error="Le fichier '%{file}' existe déjà".trn(:file => new_file)
        elsif !File.file?(file_old)
          error="Le fichier '%{file}' n'existe pas".trn(:file => old_file)
        else
            File.rename(file_old,file)
        end
    rescue => ex
      error = "Erreur lors du changement de nom du fichier. Vérifier que le nom se compose de caractères acceptés.".trn
    end
    error
  end

  def self.save_file(upload, options={})
    return if upload.blank?
    # create the file path    
    name  = options[:name] || self.sanitize_filename(upload.original_filename)    
    name  = "#{Time.now.strftime('%Y%m%d%H%M%S')}_#{name}" if options[:timing].presence == true     
    name  = "#{options[:prefix]}_#{name}" unless options[:prefix].blank?

    path = options[:directory] || File.join(Rails.root, 'public').freeze
    FileUtils.mkdir_p(path) unless File.directory?(path)
    
    path_file   = File.join(path, name)
    # write the file
    File.open(path_file, "wb") { |f| f.write(upload.read) }
    return path_file
  end 

  def self.get_menu_list
    menus = []
    self.order('name').all.each do |d|
      menus << [d.description, {:controller => 'dir_managers', :action => 'explorer' , :name_dir => d.name},d.name]
    end
    return menus 
  end

private


  def self.sanitize_filename(filename,add_caract='')
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
  
    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-#{add_caract}]+/i, '_' }
  
    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end

  def check_dependances
    unless self.dir_accesses.empty?
      self.dir_accesses.destroy_all
    end
    return (self.errors.empty?)
  end


end