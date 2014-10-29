# encoding: UTF-8

class PostitProcessesController < ApplicationController

  has_es_interface_controllers


  def list
    sorting :default => "postit_processes.name"
    session[:conditions] = create_conditions

    @postit_processes = PostitProcess.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions]

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'list_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  #Create an empty new in order to be used in the new setup screen -
  def new
    @postit_process = PostitProcess.new()
  end
   

  # Save the Setup to database -
  def create
    params[:postit_process][:completed]      = "N"
    
    @postit_process = PostitProcess.new(params[:postit_process])
    if @postit_process.save
      flash[:notice] = 'Ce processus a été correctement créé.'.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit
    id = params[:id].presence || 0 
    @postit_process = PostitProcess.find(id)
  end
  
  # Update the Setup in the database -
  def update
    @postit_process = PostitProcess.find_by_id(params[:id])
    if @postit_process.update_attributes(params[:postit_process])
      flash[:notice] = 'Ce processus a été correctement modifié.'.trn
      redirect_to :action => "list"
    else
      render :action => 'edit'
    end
  end
  
  # Delete the Setup from database -
  def destroy
    tmp_element_error = PostitProcess.new
    tmp = PostitProcess.find_by_id(params[:id])
    if tmp
      name = tmp.name
      if params[:mode_action].presence=="delete"
        tmp.postit_phases.each do |ph|
          ph.postit_lists.each do |l|
            l.postit_tasks.destroy_all 
          end
          ph.postit_lists.destroy_all 
        end
        tmp.postit_phases.destroy_all
      end
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = 'Ce processus a correctement été supprimé.'.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  def copy_from
    id = params[:id].presence || 0 
    postit_process = PostitProcess.find(id) 

    cloned = postit_process.deep_clone :include => [:postit_phases => [:postit_lists => [:postit_tasks => [:action_users]]]]
    cloned[:name] = "copie de %{name}".trn(:name => postit_process.name) 
    cloned[:templatable] = "N" 
    cloned[:owner_id] = current_user.id 
    cloned.save
    redirect_to :action => 'list'
  end

  def link_phase
    id = params[:id].presence || 0 
    @postit_process  = PostitProcess.find(id)    
    @phase_chosen  = @postit_process.postit_phases.order("id")
    @phase_free    = []
    PostitPhase.all(:order => "name").each do |p| 
      @phase_free << [p.name,p.id] if !p.postit_process && (p.status=='NONE' || (p.status=='COMPLETE' && p.postit_lists.size==0)) 
    end
  end

  def unlink_phase
    id = params[:id].presence || 0 
    postit_phase = PostitPhase.find(id)    
    postit_process = postit_phase.postit_process  
    phase_ids  = postit_process.postit_phase_ids - [id.to_i]      
    postit_process.update_attributes(:postit_phase_ids => list_ids)
    redirect_to :action => 'link_phase', :id => postit_process.id
  end

  def save_link_phase
    id = params[:id].presence || 0 
    postit_process = PostitProcess.find(id)    
    phase_ids  = []
    phase_ids  = postit_process.postit_phase_ids + params[:phase][:free]      
    postit_process.update_attributes(:postit_phase_ids => phase_ids)
    redirect_to :action => 'link_phase', :id => postit_process.id
  end


  def add_link_phase
    id = params[:id].presence || 0 
    postit_process = PostitProcess.find_by_id(id)    
    postit_phase = PostitPhase.create(:name => 'Nouvelle phase'.trn, :description => 'Nouvelle phase'.trn, :templatable => 'N', :completed => 'N', :owner_id => current_user.id)
    postit_process.postit_phases << postit_phase
    postit_process.save
    redirect_to :action => 'link_phase', :id => postit_process.id
  end

  def edit_phase
    id = params[:id].presence || 0
    @postit_phase = PostitPhase.find(id)    
    redirect_to :controller => 'postit_phases',:action => 'edit', :id => @postit_phase.id
  end


private

  def create_conditions

    conditions = ["(postit_processes.owner_id in (?))",[0,(current_user.blank? ? 0 : current_user.id)]]

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(postit_processes.name) LIKE UPPER(?) OR UPPER(postit_processes.description) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
    end

    return conditions
    
  end

end
