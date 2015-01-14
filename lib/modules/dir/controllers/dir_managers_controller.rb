# encoding: UTF-8

class DirManagersController < ApplicationController

  has_es_interface_controllers

  @@default_sort    = 'name' 
  @@param_name      = "element"
  @@model           = DirManager
  @@msg_creation    = 'Ce répertoire a été correctement créé.'
  @@msg_update      = 'Ce répertoire a été correctement modifié.'
  @@msg_delete      = 'Ce répertoire a correctement été supprimé.'
  @@field_print     = ["name","description","real_dir"]
  @@name_print      = ["Nom","Description","Répertoire"]
  @@condition_info  = ['(UPPER(dir_managers.name) LIKE UPPER(?) OR UPPER(dir_managers.description) LIKE UPPER(?) OR UPPER(dir_managers.real_dir) LIKE UPPER(?))',3]
  
  def list
    sorting :default => @@default_sort
    session[:conditions] = create_conditions
    @collections = @@model.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions]
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'list_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  def explorer_action
    #flash.delete(:copy_file)
    #flash.delete(:copy_cut)

    id = params[:id].presence||0
    @dir_manager = DirManager.find_by_id(id)
    @sub_dir = params[:sub_dir].presence||''
    
    get_dir_content(id)
    path          = File.join(@parent,@sub_dir||'')
    file          = File.join(@parent,@sub_dir||'',params[:file_name]||'')    

    @new_dir      = (params[:dir_manager_info].present? and params[:dir_manager_info][:new_dir].present?) ? params[:dir_manager_info][:new_dir] : ''

    dir_selected  = params[:dir_name]||''
    file_selected = params[:file_name]||''
    
    flash.keep[:copy_file]
    
    error_txt     = ""
    
    tmp_action = params[:action_type].presence||''
    case tmp_action
      when "delete_all_files"
        if @dir_manager.action_available?('dir_del')
          error_txt = DirManager.delete_all_files(path)
        else
          error_txt = "Vous n'avez pas le droit de supprimer tout un répertoire".trn
        end
      when "paste_file"
        if @dir_manager.action_available?('file_create')
          error_txt = DirManager.paste_file(path,File.join(@parent,flash[:copy_file]),flash[:copy_cut])
        else
          error_txt = "Vous n'avez pas le droit de copier/déplacer un nouveau fichier".trn
        end
        if error_txt.blank?
          flash.delete(:copy_file)
          flash.delete(:copy_cut)
        end
      when "rename_file"
        if @dir_manager.action_available?('file_rename')
          unless @new_dir.blank?
            error_txt = DirManager.rename_file(path,file_selected,@new_dir)
            @new_dir = '' if error_txt.blank?
          else
            error_txt = "Le nouveau nom de fichier doit être renseigné".trn
          end     
        else
          error_txt = "Vous n'avez pas le droit de renommer un fichier".trn
        end
      when "delete_file"
        if @dir_manager.action_available?('file_del')
          error_txt = DirManager.delete_file(path,file_selected)
        else
          error_txt = "Vous n'avez pas le droit de supprimer un fichier".trn
        end
      when "copy_file"
        if @dir_manager.action_available?('file_create')
          flash[:copy_file] = @sub_dir.blank? ? file_selected : File.join(@sub_dir,file_selected)
          flash[:copy_cut]  = 'copy'
        else
          error_txt = "Vous n'avez pas le droit de copier un fichier".trn
        end
      when "cut_file"
        if @dir_manager.action_available?('file_create')
          flash[:copy_file] = @sub_dir.blank? ? file_selected : File.join(@sub_dir,file_selected)
          flash[:copy_cut]  = 'cut'
        else
          error_txt = "Vous n'avez pas le droit de déplacer un fichier".trn
        end
      when "cancel_copy"
        flash.delete(:copy_file)
        flash.delete(:copy_cut)
      when "cancel_upload"
      when "upload_file"
        if @dir_manager.action_available?('file_upload')
          if params[:dir_manager_info].present? && params[:dir_manager_info][:upload_file].present?
            upload_file = params[:dir_manager_info][:upload_file]
            size = (@dir_manager.limit_size || (1024 * 1024)).to_f
            if upload_file.size > size
              error_txt = "Le fichier à charger est trop volumineux. Il doit être inférieur à %{size}.".trn(:size => size.nice_bytes)
            else
              error_txt = ''
              unless File.file?(File.join(path,upload_file.original_filename))
                error_txt = "Vous n'avez pas le droit de créer un nouveau fichier".trn unless @dir_manager.action_available?('file_create') 
              else
                error_txt = "Vous n'avez pas le droit de modifier un fichier".trn unless @dir_manager.action_available?('file_update') 
              end
              DirManager.save_file(upload_file,{:name => upload_file.original_filename, :directory => path}) if error_txt.blank?
            end
          else
            error_txt = "Le fichier à charger doit être renseigné".trn
          end
        else
          error_txt = "Vous n'avez pas le droit de charger un fichier".trn
        end
      when "delete_dir"
        if @dir_manager.action_available?('dir_del')
          error_txt = DirManager.delete_dir(path,dir_selected)
        else
          error_txt = "Vous n'avez pas le droit de supprimer un répertoire".trn
        end
      when "rename_dir"
        if @dir_manager.action_available?('dir_rename')
          unless @new_dir.blank?
            error_txt = DirManager.rename_dir(path,dir_selected,@new_dir)
            @new_dir = '' if error_txt.blank?
          else
            error_txt = "Le nouveau nom de répertoire doit être renseigné".trn
          end     
        else
          error_txt = "Vous n'avez pas le droit de renommer un répertoire".trn
        end
      when "new_dir"
        if @dir_manager.action_available?('dir_create')
          unless @new_dir.blank?
            error_txt = DirManager.create_dir(path,@new_dir)
            @new_dir = '' if error_txt.blank?
          else
            error_txt = "Le nouveau répertoire doit être renseigné".trn
          end     
        else
          error_txt = "Vous n'avez pas le droit de créer un répertoire".trn
        end
      when "download_file"
        if @dir_manager.action_available?('file_download')
          if File.file?(file)
            download_file file
            return
          end
        else
          error_txt = "Vous n'avez pas le droit de télécharger un fichier".trn
        end
    end

    

    if error_txt.blank?
      get_dir_content
      flash.delete(:error_dir) 
    else
      flash[:error_dir] = error_txt
    end
    
    respond_to do |format|
      format.html {
        session[:error_txt]=error_txt
        redirect_to :action => "explorer", :id => params[:id], :sub_dir => params[:sub_dir]
        }
      format.js do 
        @element_id, @partial = 'explorer', 'explorer'
        render 'shared/replace_content'
      end
    end
  end
  
  
  def explorer

    ident = params[:id].presence||''
    if ident.blank?
      ident = params[:name_dir].presence||''      
      @dir_manager = DirManager.find_by_name(ident)
    else  
      @dir_manager = DirManager.find_by_id(ident)
    end
    @sub_dir = params[:sub_dir].presence||''

    get_dir_content(ident)

    error_txt = session[:error_txt].presence||''
    session.delete(:error_txt)
    if error_txt.blank?
      flash.delete(:error_dir) 
    else
      flash[:error_dir] = error_txt
    end


    
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'explorer', 'explorer'
        render 'shared/replace_content'
      end
    end

  end
    
  
  def right_dir
    sorting :default => 'name'
    @dir = DirManager.find_by_id(params[:id])
    @collection_accesses = @dir.dir_accesses.order(@sort)
    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'list_div', 'list_right'
        render 'shared/replace_content'
      end
    end
  end
  
  def new_right
    @dir = DirManager.find_by_id(params[:id])
    @element = DirAccess.new()
  end
  
  #Create an empty new in order to be used in the new setup screen -
  def new
    @element = @@model.new()
  end
   
  # Save the Setup to database -
  def create_right
    @dir = DirManager.find_by_id(params[:id])
    @element = DirAccess.new(params[:element])
    @element.dir_manager_id = @dir.id
    if @element.save
      flash[:notice] = "Ce droit de répertoire a été correctement créé.".trn
      redirect_to :action => "right_dir",:id => params[:id]
    else
      render :action => 'new_right'
    end
  end

  # Save the Setup to database -
  def create
    @element = @@model.new(params[@@param_name.to_sym])
    if @element.save
      flash[:notice] = @@msg_creation.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit_right
    id = params[:id].presence || 0 
    @element = DirAccess.find(id)
    @dir = @element.dir_manager
  end
  
  # display the selected Setup
  def edit
    id = params[:id].presence || 0 
    @element = @@model.find(id)
  end
  
  # Update the Setup in the database -
  def update_right
    @element = DirAccess.find_by_id(params[:id])
    @dir = @element.dir_manager
    if @element.update_attributes(params[:element])
      flash[:notice] = "Ce droit de répertoire a été correctement modifié.".trn
      redirect_to :action => "right_dir",:id => @dir.id 
    else
      render :action => 'edit_right', :id => params[:id]
    end
  end
  
  # Update the Setup in the database -
  def update
    @element = @@model.find_by_id(params[:id])
    if @element.update_attributes(params[@@param_name.to_sym])
      flash[:notice] = @@msg_update.trn
      redirect_to :action => "list"
    else
      render :action => 'edit'
    end
  end
  
  # Delete the Setup from database -
  def destroy_right

    tmp_element_error = DirAccess.new
    tmp = DirAccess.find_by_id(params[:id])
    @dir = tmp.dir_manager
    if tmp
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "Ce droit répertoire a correctement été supprimé.".trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "right_dir", :id => @dir.id
  end

  # Delete the Setup from database -
  def destroy
    tmp_element_error = @@model.new
    tmp = @@model.find(params[:id])
    if tmp
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = @@msg_delete.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  # setups export to csv
  def export_csv
    # Find all Setup with the stored restrictions
    sorting :default => @@default_sort
    collection = @@model.find :all, :order => @sort, :conditions => session[:conditions]
    # Creation of the file
    file_name = "#{@@param_name}_export_" + current_user.id.to_s + ".csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv <<  @@name_print.map{|n| n.trn}
       collection.each do |element|
          csv << @@field_print.map{|f| element[f]}
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end

private

  def create_conditions
    conditions = []
    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += @@condition_info[0] 
      @@condition_info[1].times do |i|
        conditions << "%#{params[:global_search]}%"
      end
    end
    return conditions
  end


  def get_dir_content(name='')
    flash.delete(:error)
    user_id = current_user.blank? ? 0 : current_user.id
    if @dir_manager
      access_file = @dir_manager.action_available?('file_view')
      access_dir  = @dir_manager.action_available?('dir_view')
      @typefile = '[DIR],' + (@dir_manager.file_ext.blank? ? '*.*' : @dir_manager.file_ext.gsub(';',','))
        
      @parent = File.join(Rails.root, @dir_manager.dir_base.local_path)
      @parent = File.join(@parent, @dir_manager.real_dir) unless @dir_manager.real_dir.blank?
      @parent = File.join(@parent, user_id.to_s) if @dir_manager.sub_dir_by_user=='Y'

      @sub_dir = '' unless access_dir

      unless @parent.blank?
        tmp_path = File.join(@parent,@sub_dir||'')        
        unless File.directory?(tmp_path)
          tmp_path = @parent
          flash[:error]="Le sous répertoire %{name} n'existe pas".trn(:name => @sub_dir)
        end           
        if File.expand_path(tmp_path).starts_with?(@parent)
          @sub_dir = File.expand_path(tmp_path)[@parent.size+1..-1]
        else
          @sub_dir = nil
        end
        FileUtils.mkdir_p(@parent) unless File.directory?(@parent)
        @dir = DirContent.new(@parent, @typefile).get_content(@sub_dir||'')
        @dir[0]=[] unless access_dir
        @dir[1]=[] unless access_file        
        unless access_dir
          @dir_tree = ''
        else
          tmp_tree = DirContent.new(@parent, @typefile).get_dir_tree_html('') #@sub_dir||''
          tmp_tree.each_with_index do |t,i|
            if t.is_a?(Array)
              t[0]= @dir_manager.name if t[0]=='..'
              t[0]= '>'+t[0] if t[1]==@sub_dir
              tmp_tree[i] = "<a data-remote='true' href='#{url_for(:controller => "dir_managers", :action => "explorer", :id => @dir_manager.id, :sub_dir => t[1])}'>#{t[0]}</a>"
            end  
          end
          @dir_tree = tmp_tree.join('')
        end
      end      
    else
      flash[:error]="Exploration du répertoire %{name} impossible".trn(:name => name)
    end
  end

end
