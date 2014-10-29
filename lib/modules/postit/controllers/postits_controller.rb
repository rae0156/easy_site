# encoding: UTF-8

class PostitsController < ApplicationController

  has_es_interface_controllers

  before_filter :init_postit

  def desktop
    get_desktop_info
  end

  def view_all_task
    session[:postit_opened] = PostitTask.all(:conditions => ["postit_list_id is NULL and checked = ? and owner_id = ? and templatable = ?","N",current_user.id,"N"]).map(&:id)
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end

  def view_task
    session[:postit_opened] = [params[:id]]
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end

  def open_task
    PostitTask.find_by_id(params[:id]).update_attributes({:checked => "N",:close_date => nil})
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end

  def close_task
    PostitTask.find_by_id(params[:id]).update_attributes({:checked => "Y",:close_date => Time.now})
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end

  def delete_task
    PostitTask.find_by_id(params[:id]).destroy
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end

  def close_task_from_list
    postit_task = PostitTask.find_by_id(params[:id])
    postit_task.update_attributes(:checked => "Y",:close_date => Time.now)
    @postit_list = postit_task.postit_list
    session[:postit_list_opened] = [postit_task.postit_list_id]
    get_desktop_info
    #session[:postit_list_opened] << @postit_list.id
    respond_to do |format|
      format.js do 
        @element_id, @partial = ["list_to_do","process_to_do","list_#{@postit_list.id}"], ["d_detail_list_todo","d_detail_process_todo",'desktop_view_list_task']
        render 'shared/replace_content'
      end
    end    
  end

  def open_task_from_list
    postit_task = PostitTask.find_by_id(params[:id])
    postit_task.update_attributes(:checked => "N",:close_date => nil)
    @postit_list = postit_task.postit_list
    session[:postit_list_opened] = [postit_task.postit_list_id]
    get_desktop_info
    #session[:postit_list_opened] << @postit_list.id
    respond_to do |format|
      format.js do 
        @element_id, @partial = ["list_to_do","process_to_do","list_#{@postit_list.id}"], ["d_detail_list_todo","d_detail_process_todo",'desktop_view_list_task']
        render 'shared/replace_content'
      end
    end    
  end

  def close_list_only
    params[:tab]=2
    postit_list = PostitList.find_by_id(params[:id])
    postit_list.update_attributes({:completed => "Y",:close_date => Time.now})
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end

  def view_list
    postit_list = PostitList.find_by_id(params[:id])
    session[:postit_list_opened] = [params[:id]]
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end

  def delete_list
    postit_list = PostitList.find_by_id(params[:id])
    postit_list.postit_tasks.destroy_all
    postit_list.destroy
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end

  def open_list
    
    PostitList.find_by_id(params[:id]).update_attributes({:completed => "N",:close_date => nil})
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end
  
  def close_list
    postit_list = PostitList.find_by_id(params[:id])
    postit_list.update_attributes({:completed => "Y",:close_date => Time.now})
    if postit_list.checkable=='Y'
      postit_list.postit_tasks.each do |t|
        t.update_attributes({:checked => "Y", :close_date => Time.now})
      end
    end
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end

  def close_process
    postit_process = PostitProcess.find_by_id(params[:id])
    postit_process.update_attributes({:completed => "Y",:close_date => Time.now})
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end



  def change_status
    process = PostitProcess.find_by_id(params[:id])
    unless process.update_attributes({:dyn_workflow_status_id => (params[:next_status_id].presence||0)})
      flash[:error] =  process.errors.full_messages.join('<BR>')
    end
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end
  end


  def delete_process
    postit_process = PostitProcess.find_by_id(params[:id])
    postit_process.postit_phases.each do |ph|
      ph.postit_lists.each do |l|
        l.postit_tasks.destroy_all
      end
      ph.postit_lists.destroy_all
    end
    postit_process.postit_phases.destroy_all
    postit_process.destroy
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end

  def open_process
    postit_process = PostitProcess.find_by_id(params[:id])
    postit_process.update_attributes({:completed => "N",:close_date => nil})
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'desktop_div', 'desktop_detail'
        render 'shared/replace_content'
      end
    end    
  end

  def refresh_all
    get_desktop_info
    respond_to do |format|
      format.js do 
        @element_id, @partial = ["task_to_do","list_to_do","process_to_do","task_done","list_done","process_done"], ["d_detail_task_todo","d_detail_list_todo","d_detail_process_todo","d_detail_task_done","d_detail_list_done","d_detail_process_done"]
        render 'shared/replace_content'
      end
    end
  end


  def new_task
    redirect_to :controller => "postit_tasks", :action => "new"
  end

  def new_todolist
    redirect_to :controller => "postit_lists", :action => "new_todolist"
  end

  def new_checklist
    redirect_to :controller => "postit_lists", :action => "new_checklist"
  end

  def init_postit
    session[:postit_opened]=[]
    session[:postit_list_opened]=[]
    session[:postit_process_opened]=[]
  end

private

  def get_desktop_info
    manage_postit_opened
    @active= ['']*10
    @active[(params[:tab]||0).to_i]='active' 
    @my_tasks_to_do     = PostitTask.all(:conditions => ["postit_list_id is NULL and checked = ? and owner_id = ? and templatable = ?","N",current_user.id,"N"], :order => "name")
    @my_tasks_done      = PostitTask.all(:conditions => ["postit_list_id is NULL and checked = ? and owner_id = ? and templatable = ?","Y",current_user.id,"N"], :order => "name")
    @my_lists_to_do     = PostitList.all(:conditions => ["postit_phase_id is NULL and completed = ? and owner_id IN (?) and templatable = ?","N",[0,current_user.id],"N"], :order => "name")
    @my_lists_done      = PostitList.all(:conditions => ["postit_phase_id is NULL and completed = ? and owner_id IN (?) and templatable = ?","Y",[0,current_user.id],"N"], :order => "name")
    @my_processes_to_do = PostitProcess.all(:conditions => ["completed = ? and owner_id IN (?) and templatable = ?","N",[0,current_user.id],"N"], :order => "name")
    @my_processes_done  = PostitProcess.all(:conditions => ["completed = ? and owner_id IN (?) and templatable = ?","Y",[0,current_user.id],"N"], :order => "name")
  end

  def manage_postit_opened
    tmp_list = session[:postit_opened].presence || []
    session[:postit_opened] = []
    tmp_list.uniq.each do |postit_id|
      session[:postit_opened] << postit_id if PostitTask.first(:conditions => ["id = ? and postit_list_id is NULL and owner_id = ? and templatable = ?",postit_id,current_user.id,"N"])
    end
    tmp_list = session[:postit_list_opened].presence || []
    session[:postit_list_opened] = []
    tmp_list.uniq.each do |postit_list_id|
      session[:postit_list_opened] << postit_list_id if PostitList.first(:conditions => ["id = ? and ((owner_id = ?  and templatable = ?) OR postit_phase_id is NOT NULL)",postit_list_id,current_user.id,"N"])
    end
  end

end
