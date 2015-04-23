# encoding: UTF-8

class PostitPhasesController < ApplicationController

  has_es_interface_controllers


  def list
    sorting :default => "postit_phases.name"
    session[:conditions] = create_conditions

    @postit_phases = PostitPhase.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions], :include => :postit_process

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
    @postit_phase = PostitPhase.new()
  end
   

  # Save the Setup to database -
  def create
    #params[:postit_phase][:completed]      = "N"
    
    @postit_phase = PostitPhase.new(params[:postit_phase])
    if @postit_phase.save
      flash[:notice] = 'Cette phase a été correctement créée.'.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit
    id = params[:id].presence || 0 
    @postit_phase = PostitPhase.find(id)
  end
  
  # Update the Setup in the database -
  def update
    @postit_phase = PostitPhase.find_by_id(params[:id])
    if @postit_phase.update_attributes(params[:postit_phase])
      flash[:notice] = 'Cette phase a été correctement modifiée.'.trn
      redirect_to :controller => (@postit_phase.postit_process ? 'postit_processes' : 'postit_phases') ,:action => (@postit_phase.postit_process ? 'link_phase' : 'list'), :id => @postit_phase.postit_process_id
    else
      render :action => 'edit'
    end

  end
  
  # Delete the Setup from database -
  def destroy
    tmp_element_error = PostitPhase.new
    tmp = PostitPhase.find_by_id(params[:id])
    if tmp
      name = tmp.name
      if params[:mode_action].presence=="delete"
        tmp.postit_lists.each do |l|
          l.postit_tasks.destroy_all 
        end
        tmp.postit_lists.destroy_all
      end
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = 'Cette phase a correctement été supprimée.'.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  def copy_from
    id = params[:id].presence || 0 
    postit_phase = PostitPhase.find(id) 

    cloned = postit_phase.deep_clone :include => [:postit_lists => [:postit_tasks => [:action_users]]]
    cloned[:name] = "copie de %{name}".trn(:name => postit_phase.name) 
    cloned[:templatable] = "N" 
    cloned[:owner_id] = current_user.id 
    cloned.save
    redirect_to :action => 'list'
  end

  def link_list
    id = params[:id].presence || 0 
    @postit_phase  = PostitPhase.find(id)    
    @list_chosen  = @postit_phase.postit_lists.order("id")
    @list_free    = []
    PostitList.all(:order => "name").each do |l| 
      @list_free << [l.name,l.id] if !l.postit_phase && (l.status=='NONE' || (l.status=='COMPLETE' && l.postit_tasks.size==0)) 
    end
  end

  def unlink_list
    id = params[:id].presence || 0 
    postit_list = PostitList.find(id)    
    postit_phase = postit_list.postit_phase  
    list_ids  = postit_phase.postit_list_ids - [id.to_i]      
    postit_phase.update_attributes(:postit_list_ids => list_ids)
    redirect_to :action => 'link_list', :id => postit_phase.id
  end

  def save_link_list
    id = params[:id].presence || 0 
    postit_phase = PostitPhase.find(id)    
    list_ids  = []
    list_ids  = postit_phase.postit_list_ids + params[:list][:free]      
    postit_phase.update_attributes(:postit_list_ids => list_ids)
    redirect_to :action => 'link_list', :id => postit_phase.id
  end


  def add_link_list
    id = params[:id].presence || 0 
    postit_phase = PostitPhase.find_by_id(id)    
    postit_list = PostitList.create(:name => 'Nouvelle liste'.trn, :description => 'Nouvelle liste'.trn, :templatable => 'N', :sequential => 'Y', :checkable => 'Y', :completed => 'N', :owner_id => current_user.id)
    postit_phase.postit_lists << postit_list
    postit_phase.save
    redirect_to :action => 'link_list', :id => postit_phase.id
  end

  def edit_list
    id = params[:id].presence || 0
    @postit_list = PostitList.find(id)    
    redirect_to :controller => 'postit_lists',:action => 'edit', :id => @postit_list.id
  end


private

  def create_conditions

    conditions = ["(postit_phases.owner_id in (?))",[0,(current_user.blank? ? 0 : current_user.id)]]

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(postit_processes.name) LIKE UPPER(?) OR UPPER(postit_phases.name) LIKE UPPER(?) OR UPPER(postit_phases.description) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
    end

    return conditions
    
  end

end
