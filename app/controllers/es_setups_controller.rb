# encoding: UTF-8

class EsSetupsController < ApplicationController
  
  
  def index
    redirect_to :action => 'list'
  end
  
  # Load the pages -
  def list

    tmp_code_action = params[:code_action] || ''
    
    #première arrivée sur la page, on montre tout
    if params[:global_search].blank? 
      @branch = "" 
      @setup = "/"
    end
    
    sorting :default => 'es_setups.path, es_setups.name'
    unless tmp_code_action == 'back' || !params[:sort].blank?
      session[:conditions_setup] = create_conditions
      session[:query_setup] = params[:global_search]
    end
    params[:global_search] = session[:query_setup]
    @setups = EsSetup.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_setup]

    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'setup_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  #Create an empty new in order to be used in the new setup screen -
  def new
    @setup = EsSetup.new()
    @setup.read_only = 'N'
  end
   
  # Save the Setup to database -
  def create
    @setup = EsSetup.new(params[:setup])
    if @setup.save
      flash[:notice] = 'Ce paramétrage a été correctement créé.'.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit
    @menu = 'accueil'
    id = params[:id].nil? ? params[:cid][0] : params[:id]
    @setup = EsSetup.find(id)
  end
  
  # Update the Setup in the database -
  def update
    @setup = EsSetup.find_by_id(params[:id])
    if @setup.update_attributes(params[:setup])
      flash[:notice] = 'Ce paramétrage a été correctement modifié.'.trn
      redirect_to :action => "list", :code_action => "back"
    else
      render :action => 'edit'
    end
  end
  
  # Delete the Setup from database -
  def destroy

    tmp_element_error = EsSetup.new
    for id in params[:cid]
      tmp = EsSetup.find(id)
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "Paramétrage".trn + " #{tmp.path} #{tmp.name} : #{tmp_error}.")
        end
      end
    end
    
    if tmp_element_error.errors.empty? 
      flash[:notice] = 'Paramétrage(s) correctement supprimée(s).'.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  # setups export to csv
  def export_csv
    # Find all Setup with the stored restrictions
    sorting :default => 'es_setups.path, es_setups.name'
    setups = EsSetup.find :all, :order => @sort, :conditions => session[:conditions_setup]
    # Creation of the file
    file_name = "setups_export_" + current_user.id.to_s + ".csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Chemin".trn,"Nom".trn,"Valeur".trn,"Type".trn, "Lecture seule".trn]
       setups.each do |t|
          csv << [t.path,t.name,t.value,t.type_data,(t.read_only=='Y' ? 'V' : '')]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end
  
  def decode_url(string)
    Iconv.conv('UTF-8','iso-8859-1', URI::unescape(string))
  end
    
  def contenttree
    @parent = params[:dir]||''
    @parent = decode_url(@parent)  #replace %20 by space
    @first = @parent == ''
    @setups = EsSetup.arbo(@parent) 
    render :layout => false
  end
  
  
  def viewtree

    param_branch = params[:branch] || '' 
    
    unless param_branch.blank?
      if param_branch.end_with?('/')
        @branch = param_branch[0...-1]
        @setup  = ''
      else
        @setup  = param_branch.split('/').last
        
        @branch = param_branch[0..-(@setup.length + 2)]
      end  
    else
      @branch = ""
      @setup = "/" 
    end
    
    sorting :default => 'es_setups.path, es_setups.name'
    unless !params[:sort].blank?
      session[:conditions_setup] = create_conditions
    end

    @setups = EsSetup.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_setup]

    @element_id, @partial = 'setup_div', 'list'
    render 'shared/replace_content', :formats => [:js]
  end

private

  def create_conditions

    conditions = []

    unless @branch.blank? 
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += 'path = ?'
      conditions << "#{@branch}"
    end   
    unless @setup.blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += 'name=?'
      conditions << "#{@setup}"
    end


    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(es_setups.name) LIKE UPPER(?) OR UPPER(es_setups.value) LIKE UPPER(?) OR UPPER(es_setups.path) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
    end


    return conditions
    
  end
  
end
