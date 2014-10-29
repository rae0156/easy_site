# encoding: UTF-8

class PostitListsController < ApplicationController

  has_es_interface_controllers


  def list

    sorting :default => "postit_lists.name"
    session[:conditions] = create_conditions

    @postit_lists = PostitList.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions], :include => :postit_phase

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
    @postit_list = PostitList.new()
  end
   
  def new_todolist
    @postit_list = PostitList.new(:name => "Nouvelle liste".trn, :description => "Nouvelle liste".trn, :sequential => 'Y', :completed => 'N', :checkable => 'N',:owner_id => current_user.id)
    render :action => "new"
  end

  def new_checklist
    @postit_list = PostitList.new(:name => "Nouvelle liste".trn, :description => "Nouvelle liste".trn, :sequential => 'Y', :completed => 'N', :checkable => 'Y',:owner_id => current_user.id)
    render :action => "new"
  end


  # Save the Setup to database -
  def create
    params[:postit_list][:completed]      = "N"
    
    @postit_list = PostitList.new(params[:postit_list])
    if @postit_list.save
      flash[:notice] = 'Cette liste a été correctement créée.'.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit
    id = params[:id].presence || 0 
    @postit_list = PostitList.find(id)
  end
  
  # Update the Setup in the database -
  def update
    @postit_list = PostitList.find_by_id(params[:id])
    if @postit_list.update_attributes(params[:postit_list])
      flash[:notice] = 'Cette liste a été correctement modifiée.'.trn
      redirect_to :controller => (@postit_list.postit_phase ? 'postit_phases' : 'postit_lists') ,:action => (@postit_list.postit_phase ? 'link_list' : 'list'), :id => @postit_list.postit_phase_id
    else
      render :action => 'edit'
    end
  end
  
  # Delete the Setup from database -
  def destroy
    tmp_element_error = PostitList.new
    tmp = PostitList.find_by_id(params[:id])
    if tmp
      name = tmp.name
      tmp.postit_tasks.destroy_all if params[:mode_action].presence=="delete"
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = 'Cette liste a correctement été supprimée.'.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  def copy_from
    id = params[:id].presence || 0 
    postit_list = PostitList.find(id) 

    cloned = postit_list.deep_clone :include => [:postit_tasks => [:action_users]]
    cloned[:name] = "copie de %{name}".trn(:name => postit_list.name) 
    cloned[:templatable] = "N" 
    cloned[:owner_id] = current_user.id 
    cloned.save
    redirect_to :action => 'list'
  end

  def link_task
    id = params[:id].presence || 0 
    @postit_list  = PostitList.find(id)    
    @task_chosen  = @postit_list.postit_tasks.order("sequence")
    @task_free    = []
    PostitTask.all(:order => "name").each do |t| 
      @task_free << [t.name,t.id] if !t.postit_list && t.checked=='N'
    end
  end

  def unlink_task
    id = params[:id].presence || 0 
    postit_task = PostitTask.find(id)    
    postit_list = postit_task.postit_list  
    task_ids  = []
    task_ids  = postit_list.postit_task_ids - [id.to_i]      
    postit_list.update_attributes(:postit_task_ids => task_ids)
    postit_task.update_attributes(:sequence => 1)
    postit_list.compress_task
    redirect_to :action => 'link_task', :id => postit_list.id
  end

  def save_link_task
    id = params[:id].presence || 0 
    postit_list = PostitList.find(id)    
    task_ids  = []
    task_ids  = postit_list.postit_task_ids + params[:task][:free]      
    postit_list.update_attributes(:postit_task_ids => task_ids)
    postit_list.compress_task
    redirect_to :action => 'link_task', :id => postit_list.id
  end

  def move_up
    id = params[:id].presence || 0 
    postit_task = PostitTask.find(id)    
    postit_list = postit_task.postit_list  
    postit_task.update_attribute('sequence',postit_task.sequence - 1.5)
    postit_list.compress_task
    redirect_to :action => 'link_task', :id => postit_list.id
  end
  
  def move_down
    id = params[:id].presence || 0 
    postit_task = PostitTask.find(id)    
    postit_list = postit_task.postit_list  
    postit_task.update_attribute('sequence',postit_task.sequence + 1.5)
    postit_list.compress_task
    redirect_to :action => 'link_task', :id => postit_list.id
  end

  def add_link_task
    id = params[:id].presence || 0 
    postit_list = PostitList.find_by_id(id)    
    postit_task = PostitTask.create(:sequence => 9999, :name => 'Nouvelle tâche'.trn, :description => 'Nouvelle tâche'.trn, :templatable => 'N', :optional => 'N', :checked => 'N', :owner_id => current_user.id)
    postit_list.postit_tasks << postit_task
    postit_list.save
    postit_list.compress_task
    redirect_to :action => 'link_task', :id => postit_list.id
  end

  def edit_task
    id = params[:id].presence || 0
    @postit_task = PostitTask.find(id)    
    redirect_to :controller => 'postit_tasks',:action => 'edit', :id => @postit_task.id
  end


private

  def create_conditions

    conditions = ["(postit_lists.owner_id in (?))",[0,(current_user.blank? ? 0 : current_user.id)]]

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(postit_phases.name) LIKE UPPER(?) OR UPPER(postit_lists.name) LIKE UPPER(?) OR UPPER(postit_lists.description) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
    end

    return conditions
    
  end

end
