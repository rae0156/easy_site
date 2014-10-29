# encoding: UTF-8

class PostitTasksController < ApplicationController

  has_es_interface_controllers


  def list

    sorting :default => "postit_tasks.name"
    session[:conditions] = create_conditions

    @postit_tasks = PostitTask.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions], :include => :postit_list

    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'list_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  #Create an empty new in order to be used in the new setup screen -
  def new
    @postit_task = PostitTask.new()
  end
   
  # Save the Setup to database -
  def create
    params[:postit_task][:sequence]     = 1
    params[:postit_task][:checked]      = "N"
    params[:postit_task][:optional]     = "N"
    
    @postit_task = PostitTask.new(params[:postit_task])
    if @postit_task.save
      flash[:notice] = 'Cette tâche a été correctement créée.'.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit
    id = params[:id].presence || 0 
    @postit_task = PostitTask.find(id)
  end
  
  # Update the Setup in the database -
  def update
    @postit_task = PostitTask.find_by_id(params[:id])
    if @postit_task.update_attributes(params[:postit_task])
      flash[:notice] = 'Cette tâche a été correctement modifiée.'.trn
      redirect_to :controller => (@postit_task.postit_list ? 'postit_lists' : 'postit_tasks') ,:action => (@postit_task.postit_list ? 'link_task' : 'list'), :id => @postit_task.postit_list_id
    else
      render :action => 'edit'
    end
  end
  
  # Delete the Setup from database -
  def destroy
    tmp_element_error = PostitTask.new
    tmp = PostitTask.find(params[:id])
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = 'Cette tâche a correctement été supprimée.'.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  # setups export to csv
  def export_csv
    # Find all Setup with the stored restrictions
    sorting :default => "name"
    collection = PostitTask.find :all, :order => @sort, :conditions => session[:conditions]
    # Creation of the file
    file_name = "postit_task_export_" + current_user.id.to_s + ".csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Nom".trn,"Description".trn,"Séquence".trn]
       collection.each do |element|
          csv << [element.name,element.description,element.sequence]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end

  def link_action
    id = params[:id].presence || 0 
    @postit_task    = PostitTask.find(id)    
    @action_chosen  = @postit_task.action_users.order("name").collect{|a| [a.name,a.id]}
    @action_free    = ActionUser.all(:conditions => (@postit_task.action_user_ids == [] ? nil : ["id not in (?)", @postit_task.action_user_ids]) , :order => "name").collect{|a| [a.name,a.id]}
  end

  def save_link_action
    id = params[:id].presence || 0 
    action_plus = params[:action_plus]
    postit_task = PostitTask.find(id)    
    action_ids  = []
    case action_plus
    when "add_all_action"
      action_ids  = ActionUser.all.map{|a| a.id}
    when "add_selected_action"
      action_ids  = postit_task.action_user_ids + params[:user_action][:free]      
    when "del_selected_action"
      action_ids  = postit_task.action_user_ids - params[:user_action][:choosen].reject(&:empty?).map{|a| a.to_i}    
    when "del_all_action"
      action_ids  = []
    end
    postit_task.update_attributes(:action_user_ids => action_ids)

    redirect_to :action => 'link_action', :id => id
  end


  def copy_from
    id = params[:id].presence || 0 
    postit_task = PostitTask.find(id) 

    cloned = postit_task.deep_clone :include => [:action_users]
    cloned[:name] = "copie de %{name}".trn(:name => postit_task.name) 
    cloned[:templatable] = "N" 
    cloned[:owner_id] = current_user.id 

    cloned.save
    redirect_to :action => 'list'
  end




private

  def create_conditions

    conditions = ["(postit_tasks.owner_id in (?))",[0,(current_user.blank? ? 0 : current_user.id)]]

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(postit_lists.name) LIKE UPPER(?) OR UPPER(postit_tasks.name) LIKE UPPER(?) OR UPPER(postit_tasks.description) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
    end

    return conditions
    
  end

end
