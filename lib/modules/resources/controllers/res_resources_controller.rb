# encoding: UTF-8

class ResResourcesController < ApplicationController
  #pour l'helper truncate
  include ActionView::Helpers::TextHelper

  has_es_interface_controllers
#  before_filter :init_user, :only => [:show_resources]
  before_filter :init_filter, :except => [:init_category]
  
  
  def show_resources_filter
    session[:copy_action]=""
    session[:copy_resource]=""
    redirect_to :action => "show_resources" 
  end
  

  def execute_multiple_action
    
    resource_ids = params["cid_r"].presence||[]
    action_ids   = params["cid_a"].presence||[]
    
    multi_action = params["multi_action"].presence||{}
    priority_id  = multi_action["value1"].presence||nil
    status_id    = multi_action["value2"].presence||nil
    user_id      = multi_action["value3"].presence||nil
    stockable    = multi_action["value4"].presence||nil

    priority_action_id,priority_resource_id = nil,nil
    tmp_pr = ResPriority.find_by_id(priority_id)
    if tmp_pr
      priority_action_id   = priority_id if tmp_pr.type_priority=='A'
      priority_resource_id = priority_id if tmp_pr.type_priority=='R'
    end

    resource_ids.each do |id|
      elem = ResResource.find_by_id(id)
      if elem
        elem.res_priority_id  = priority_resource_id unless priority_resource_id.blank? 
        elem.res_status_id    = status_id unless status_id.blank?
        elem.es_user_id       = user_id unless user_id.blank?
        elem.qty_not_used     = 0 if stockable=='N' 
        elem.stockable        = stockable unless stockable.blank?
        elem.save
      end
    end
    
    action_ids.each do |id|
      elem = ResAction.find_by_id(id)
      if elem
        elem.res_priority_id = priority_action_id unless priority_action_id.blank? 
        elem.res_status_id    = status_id unless status_id.blank?
        elem.es_user_id       = user_id unless user_id.blank?
        elem.save
      end
    end
    
    init_current_category
    
    respond_to do |format|
      format.html {}
      format.js do 
        @element_id, @partial = 'resource_div', 'resource'
        render 'shared/replace_content'
      end
    end
  end

  def lock_resource
    
    ResResource.set_message_lock
    
    init_current_category
    
    respond_to do |format|
      format.html {}
      format.js do 
        @element_id, @partial = 'resource_div', 'resource'
        render 'shared/replace_content'
      end
    end
  end


  def clean_tools

    @res_sort = {}
    session[:res_sort] = @res_sort
    @res_where = {}
    session[:res_where] = @res_where

    init_current_category
    
    respond_to do |format|
      format.html {}
      format.js do 
        @element_id, @partial = ['resource_tool_div','resource_filter_div'], ['resource_tool','resource_filter']
        render 'shared/replace_content'
      end
    end
    
  end
  

  def show_resources

    init_current_category
    
    respond_to do |format|
      format.html {    session[:copy_action_multiple],session[:copy_resource_multiple]="","" }
      format.js do 
        @element_id, @partial = 'resource_div', 'resource'
        render 'shared/replace_content'
      end
    end
    
  end
  
  
  def init_category
    @year=params[:ajax_param][:filter][:year]
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_filter_cat_div', 'resource_filter_cat'
        render 'shared/replace_content'
      end
    end
  end
  
  def action_down
    id = params[:id]
    user = params[:user] 
    action = ResAction.find_by_id(id)
    other_action = action.next(user)
    if other_action
      tmp_sequence = other_action.sequence
      other_action.update_attribute('sequence',action.sequence)
      action.update_attribute('sequence',tmp_sequence)
    end
    redirect_to :action => "show_resources" 
  end

  def action_up
    id = params[:id]
    user = params[:user] 
    action = ResAction.find_by_id(id)
    other_action = action.previous(user)
    if other_action
      tmp_sequence = other_action.sequence
      other_action.update_attribute('sequence',action.sequence)
      action.update_attribute('sequence',tmp_sequence)
    end
    redirect_to :action => "show_resources" 
  end

  
  def action_paste
    id = params[:id]
    user = params[:user] 
    action = ResAction.find_by_id(id)
    other_action = ResAction.find_by_id(session[:copy_action])
    if other_action
      other_action.update_attribute('sequence',action.sequence-0.5)
      other_action.compress_sequence
      session[:copy_action]=""
    end
    redirect_to :action => "show_resources" 
  end

  
  def action_copy
    id = params[:id]
    session[:copy_action]=ResAction.find_by_id(id)
    redirect_to :action => "show_resources" 
  end

  def copy_multiple
    resource_ids = params["cid_r"].presence||[]
    action_ids   = params["cid_a"].presence||[]
    session[:copy_resource_multiple] = (resource_ids.size > 0 ? resource_ids : "")
    session[:copy_action_multiple]   = (action_ids.size > 0 ? action_ids : "")
    
    if resource_ids.size > 0 && action_ids.size > 0
      session[:copy_resource_multiple] = ""
      flash[:error_message_ajax] = "Des ressources sont sélectionnées avec des actions, elle ne seront pas copiées individuellement. Ne sélectionnez que des actions, car leurs ressources les suivront lors de la copie.".trn
    end

    init_current_category
    
    respond_to do |format|
      format.html {}
      format.js do 
        @element_id, @partial = ['resource_tool_div','resource_filter_div','message_ajax'], ['resource_tool','resource_filter','layouts/part_message_ajax']
        render 'shared/replace_content'
      end
    end
  end

  def cancel_copy_multiple
    session[:copy_action_multiple]=""
    session[:copy_resource_multiple]=""

    init_current_category
    
    respond_to do |format|
      format.html {}
      format.js do 
        @element_id, @partial = ['resource_tool_div','resource_filter_div','message_ajax'], ['resource_tool','resource_filter','layouts/part_message_ajax']
        render 'shared/replace_content'
      end
    end
  end

  def paste_multiple_action
    
    ids = session[:copy_action_multiple]||[]
    
    cat_to,where = "0","TOP"
    if params[:copy_multiple].present?
      cat_to,where = (params[:copy_multiple][:category].presence||"0").to_i,(params[:copy_multiple][:where].presence||"")
    end
    
    actions,cats_from=[],[cat_to]
    msgs=[]
    if cat_to==0
      msgs << "Vous devez sélectionner une catégorie".trn
    elsif ids.size > 1000
      msgs << "Vous ne pouvez pas copier plus de %{nbr} actions à la fois".trn(:nbr => 1000)
    else
      ids.each do |id|
        act= ResAction.find_by_id(id)
        if act
          #if act.res_category_id==cat_to
          #  msgs << "Vous ne pouvez pas copier des éléments de la catégorie '%{cat}' vers elle-même.".trn(:cat => act.res_category.description) 
          #  break 
          #else
            cats_from << act.res_category_id unless cats_from.include?(act.res_category_id)
            actions << act
          #end
        end
      end      
    end

    if msgs.size == 0

      tmp_num= (where=='BOTTOM' ? 99999999 : -99999999)
      actions.each do |a|
        tmp_num+=1
        tmp_num= tmp_num.round(5)
        a.update_attributes(:sequence=>tmp_num, :res_category_id => cat_to)
        a.res_resources.each do |r|
          tmp_num+=1
          tmp_num= tmp_num.round(5)
          r.update_attributes(:sequence=>tmp_num, :res_category_id => cat_to)
        end unless a.res_category_id==cat_to
      end
      
      cats_from.each do |c_id|
        ressource = ResResource.find_by_res_category_id(c_id)
        ressource.compress_sequence if ressource
        action = ResAction.find_by_res_category_id(c_id)
        action.compress_sequence if action
      end
            
      session[:copy_action_multiple]=""
      session[:copy_resource_multiple]=""
    end
    
    respond_to do |format|
      format.html {}
      format.js do
        if msgs.size > 0
          flash[:error_message_ajax] = msgs.join('<BR>').html_safe 
          @element_id, @partial = ['resource_tool_div','resource_filter_div','message_ajax'], ['resource_tool','resource_filter','layouts/part_message_ajax']
          render 'shared/replace_content'
        else
          redirect_to :action => "show_resources" 
        end       
      end
    end
    
  end

  def paste_multiple_resource
    
    ids = session[:copy_resource_multiple]||[]
    
    where = "TOP"
    if params[:copy_multiple].present?
      where = (params[:copy_multiple][:where].presence||"")
    end
    
    resources,cats_from=[],[]
    msgs=[]
    if ids.size > 1000
      msgs << "Vous ne pouvez pas copier plus de %{nbr} ressources à la fois".trn(:nbr => 1000)
    else
      ids.each do |id|
        res= ResResource.find_by_id(id)
        if res
          cats_from << res.res_category_id unless cats_from.include?(res.res_category_id)
          resources << res
        end
      end      
    end

    if msgs.size == 0

      tmp_num= (where=='BOTTOM' ? 99999999 : -99999999)
      resources.each do |r|
        tmp_num+=1
        tmp_num= tmp_num.round(5)
        r.update_attributes(:sequence=>tmp_num)
      end
      
      cats_from.each do |c_id|
        ressource = ResResource.find_by_res_category_id(c_id)
        ressource.compress_sequence if ressource
      end
            
      session[:copy_action_multiple]=""
      session[:copy_resource_multiple]=""
    end
    
    respond_to do |format|
      format.html {}
      format.js do
        if msgs.size > 0
          flash[:error_message_ajax] = msgs.join('<BR>').html_safe 
          @element_id, @partial = ['resource_tool_div','resource_filter_div','message_ajax'], ['resource_tool','resource_filter','layouts/part_message_ajax']
          render 'shared/replace_content'
        else
          redirect_to :action => "show_resources" 
        end       
      end
    end
    
  end


  def resource_paste
    id = params[:id]
    user = params[:user] 
    resource = ResResource.find_by_id(id)
    other_resource = ResResource.find_by_id(session[:copy_resource])
    if other_resource
      other_resource.update_attribute('sequence',resource.sequence-0.5)
      other_resource.compress_sequence
      session[:copy_resource]=""
    end
    redirect_to :action => "show_resources" 
  end

  def resource_copy
    id = params[:id]
    session[:copy_resource]=ResResource.find_by_id(id)
    redirect_to :action => "show_resources" 
  end
  
  def resource_down
    id = params[:id]
    user = params[:user] 
    resource = ResResource.find_by_id(id)
    other_resource = resource.next(user)
    if other_resource
      tmp_sequence = other_resource.sequence
      other_resource.update_attribute('sequence',resource.sequence)
      resource.update_attribute('sequence',tmp_sequence)
    end
    redirect_to :action => "show_resources" 
  end

  def resource_up
    id = params[:id]
    user = params[:user] 
    resource = ResResource.find_by_id(id)
    other_resource = resource.previous(user) 
    if other_resource
      tmp_sequence = other_resource.sequence
      other_resource.update_attribute('sequence',resource.sequence)
      resource.update_attribute('sequence',tmp_sequence)
    end
    redirect_to :action => "show_resources" 
  end
  
  def eval_down
    id = params[:id]
    eval = ResEval.find_by_id(id)
    other_eval = eval.next
    if other_eval
      tmp_sequence = other_eval.sequence
      other_eval.update_attribute('sequence',eval.sequence)
      eval.update_attribute('sequence',tmp_sequence)
    end
    redirect_to :action => "show_resources" 
  end

  def eval_up
    id = params[:id]
    eval = ResEval.find_by_id(id)
    other_eval = eval.previous
    if other_eval
      tmp_sequence = other_eval.sequence
      other_eval.update_attribute('sequence',eval.sequence)
      eval.update_attribute('sequence',tmp_sequence)
    end
    redirect_to :action => "show_resources" 
  end
  
  def action_priority_down
    action = ResAction.find_by_id(params[:id])
    action.update_attribute("res_priority", ResPriority.find_by_id(action.res_priority_id).previous)
    redirect_to :action => "show_resources"
  end
  
  def action_priority_up
    action = ResAction.find_by_id(params[:id])
    action.update_attribute("res_priority", ResPriority.find_by_id(action.res_priority_id).next)
    redirect_to :action => "show_resources"
  end
  
  def action_change_status
    action = ResAction.find_by_id(params[:id])
    action.update_attribute("res_status_id", params[:status_id])
    redirect_to :action => "show_resources"
  end

  def action_change_priority
    action = ResAction.find_by_id(params[:id])
    action.update_attribute("res_priority_id", params[:status_id])
    redirect_to :action => "show_resources"
  end

  def action_insert_end

   @object = ResAction.new(:res_category_id => params[:id], :sequence => -1)

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def action_insert_resource
   resource = ResAction.find_by_id(params[:id])
   @object  = ResResource.new(:res_category_id => resource.res_category_id, :sequence => -1, :res_action_id => resource.id, :stockable => 'Y')

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def action_insert_before
    action  = ResAction.find_by_id(params[:id])
    @object = ResAction.new(:res_category_id => action.res_category_id, :sequence => action.sequence )

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def action_edit

   @object = ResAction.find_by_id(params[:id])

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def action_delete_with_resource
    @object = ResAction.find_by_id(params[:id])
    @object.res_resources.destroy_all
    tmp_resource = ResResource.new(:res_category_id => @object.res_category_id)
    tmp_resource.compress_sequence
    @object.destroy
    @object.compress_sequence
    flash[:message_ajax] = "Suppression réussie".trn
    redirect_to :action => "show_resources"
  end

  def action_delete
    @object = ResAction.find_by_id(params[:id])
    @object.destroy
    @object.compress_sequence
    flash[:message_ajax] = "Suppression réussie".trn
    redirect_to :action => "show_resources"
  end

  def update_description

   @object = ResCategory.find_by_id(params[:id])

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def resource_priority_down
    resource = ResResource.find_by_id(params[:id])
    resource.update_attribute("res_priority", ResPriority.find_by_id(resource.res_priority_id).previous)
    redirect_to :action => "show_resources"
  end
  
  def resource_priority_up
    resource = ResResource.find_by_id(params[:id])
    resource.update_attribute("res_priority", ResPriority.find_by_id(resource.res_priority_id).next)
    redirect_to :action => "show_resources"
  end
  
  def ressource_change_status
    resource = ResResource.find_by_id(params[:id])
    resource.update_attribute("res_status_id", params[:status_id])
    redirect_to :action => "show_resources"
  end

  def ressource_change_priority
    resource = ResResource.find_by_id(params[:id])
    resource.update_attribute("res_priority_id", params[:status_id])
    redirect_to :action => "show_resources"
  end

  def resource_insert_end

   @object = ResResource.new(:res_category_id => params[:id], :sequence => -1, :stockable => 'Y')

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def resource_insert_before
    resource= ResResource.find_by_id(params[:id])
    @object = ResResource.new(:res_category_id => resource.res_category_id, :sequence => resource.sequence, :stockable => 'Y' )

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def resource_edit

   @object = ResResource.find_by_id(params[:id])

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def resource_delete
    @object = ResResource.find_by_id(params[:id])
    @object.destroy
    @object.compress_sequence
    flash[:message_ajax] = "Suppression réussie".trn
    redirect_to :action => "show_resources"
  end

  def resource_refresh_stock
    if params[:id]
      @object = ResResource.find_by_id(params[:id])
    else
      @object = ResResource.new
    end
    @object.attributes = params[:object]
    @object.qty_not_used = 0 if (@object.stockable||'N') == 'N'
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'form_resource_stock', 'form_resource_stock'
#        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def eval_insert_end

    @object = ResEval.new(:res_category_id => params[:id], :sequence => -1, :year => Date.today.year)       

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def eval_edit

   @object = ResEval.find_by_id(params[:id])

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
        render 'shared/replace_content'
      end
    end
  end

  def eval_delete
    @object = ResEval.find_by_id(params[:id])
    @object.destroy
    @object.compress_sequence
    flash[:message_ajax] = "Suppression réussie".trn
    redirect_to :action => "show_resources"
  end

  def create_action
    
    id          = params[:id]
    object_type = params[:object_type]
    do_refresh  = params[:refresh].presence||'Y'
    
    
    if id
      @object = object_type.constantize.find_by_id(id)
    else  
      @object = object_type.constantize.new
    end
    new_record  = @object.new_record?

    @object.attributes = params[:object]
    case object_type
    when "ResEval"
      @object.datetime = DateTime.now
      @object.es_user_id = current_user.id
    when "ResResource"
      if (@object.stockable||'N') == 'N'
        @object.qty_not_used = 0
      else
        @object.qty_not_used ||= 0
      end
         
    end
    
    if @object.valid?

      flash[:message_ajax] = new_record ? "Création réussie".trn : "Modification réussie".trn
      @object.save(validate: false)
      @object.reload

      unless id
        if @object.sequence == -1
          #tmp_obj = @object.last
          @object.sequence = 999999 #tmp_obj ? tmp_obj.sequence + 1 : 1
        else
          @object.sequence = @object.sequence - 0.5
        end
      end
      
      @object.name = (object_type.underscore.split('_')[1] + @object.id.to_s) if new_record && ["ResAction", "ResResource"].include?(object_type)
      @object.save
      @object.compress_sequence unless id
      
      init_current_category
      @element_id, @partial = 'resource_div', 'resource'
    else
      #flash[:error_message_ajax] = @object.new_record? ? "Une erreur est apparue lors de la création".trn : "Une erreur est apparue lors de la modification".trn
      do_refresh = "Y"
      @element_id, @partial = 'resource_edit_div', 'new_edit_resource'
    end
    
    respond_to do |format|
      format.js do 
        #@element_id, @partial = 'resource_div', 'new_edit_resource'
        if do_refresh=='Y'
          render 'shared/replace_content'
        else
          render :nothing => true     
        end
      end
    end
  end
  
  def create_other
    
    if  ResStatus.get_default_status.blank?
      init_current_category
      flash[:error_message_ajax] = "Le statut par défaut n'est pas paramétré".trn
      @element_id, @partial = 'resource_div', 'resource'
#    elsif ResCategory.where(:name => params[:year], :parent_id => 0).first.check_stock==false
#      init_current_category
#      flash[:error_message_ajax] = "Impossible de copier cette année, car des erreurs de stock existent".trn
#      @element_id, @partial = 'resource_div', 'resource'
    else
      @object = ResCategoryYear.new(:name => params[:year])
      @element_id, @partial = 'resource_div', 'choose_name'
    end
    
    respond_to do |format|
      format.html {}
      format.js do 
        render 'shared/replace_content'
      end
    end
    
  end
  
  def save_other
    @object = ResCategoryYear.new(:name => params[:object][:name], :parent_id => 0)
    
    if @object.valid?
      obj_source = ResCategoryYear.where(:name => params[:year], :parent_id => 0).first
      obj_parent_cloned = obj_source.deep_clone
      obj_parent_cloned[:name] = params[:object][:name] 
      obj_parent_cloned[:parent_id] = 0
      obj_parent_cloned[:sequence] = 999999999
      obj_parent_cloned.save
      obj_source.child_ids.each do |cat_id|
        obj_cloned = ResCategory.find_by_id(cat_id).deep_clone :include => [:res_actions, :res_evals, :res_resources]
        obj_cloned.parent_id = obj_parent_cloned.id
        obj_cloned.save
        
        if obj_cloned.errors.size == 0
          status_id = ResStatus.get_default_status(true)
          obj_cloned.res_resources.each do |r|
            r.res_status_id = status_id
            if (r.stockable||'N')=='Y'
              #r.quantity = r.qty_used unless (r.qty_used||0)==0
              r.qty_not_used = 0
            end
            
            r.start_date = (r.start_date.presence||Date.today).change(:year => obj_parent_cloned[:name].to_i) if r.res_when_start_id.blank?
            r.end_date = (r.end_date.presence||Date.today).change(:year => obj_parent_cloned[:name].to_i) if r.res_when_end_id.blank?
            
            if r.res_action_id
              tmp_action = ResAction.where(:name => "action#{r.res_action_id}", :res_category_id => obj_cloned.id).first
              r.res_action_id = tmp_action.id if tmp_action
            end
            r.name = "resource#{r.id}"
            r.save
          end
          obj_cloned.res_actions.each do |a|
            a.res_status_id = status_id
            a.name = "action#{a.id}"

            a.start_date = (a.start_date.presence||Date.today).change(:year => obj_parent_cloned[:name].to_i) if a.res_when_start_id.blank?
            a.end_date = (a.end_date.presence||Date.today).change(:year => obj_parent_cloned[:name].to_i) if a.res_when_end_id.blank?

            a.save
          end
        end
        session[:res_year] = obj_parent_cloned.name
      end if obj_parent_cloned.errors.size == 0

      obj_source_2 = ResCategory.find_by_id(obj_source.id)
      obj_source_2.res_stocks.each do |st|
        obj_cloned = st.deep_clone
        obj_cloned.res_category_id  = obj_parent_cloned.id
        obj_cloned.quantity         = st.qty_not_used
        obj_cloned.quantity_added   = 0
        obj_cloned.qty_not_used     = 0
        obj_cloned.save
      end      


      
      redirect_to :action => "show_resources" 
    else  
      respond_to do |format|
        format.html {}
        format.js do 
          @element_id, @partial = 'resource_div', 'choose_name'
          render 'shared/replace_content'
        end
      end
    end
    
  end
  
  def remove
    setup = EsSetup.get_setup('ressource_suppression_action',nil)
    
    cat = ResCategoryYear.where(:name => params[:year], :parent_id => 0).first
    if cat
      if setup=='supprimer'
        cat.child_ids.each do |c_id|
          c = ResCategory.find_by_id(c_id)
          c.res_evals.destroy_all
          c.res_actions.destroy_all
          c.res_resources.destroy_all
          c.destroy
        end
        ResCategory.where(:name => params[:year], :parent_id => 0).first.res_stocks.destroy_all
        cat.destroy
        flash[:message_ajax] = "Ressources supprimées".trn
      else
        cat.update_attribute('actif','N')
        flash[:message_ajax] = "Ressources désactivées".trn
      end
    end
        
    redirect_to :action => "show_resources" 
  end
  
  def print
    
    
    if @year.blank?
      flash[:message_ajax] = "Veuillez sélectionner une année".trn 
      redirect_to :action => "show_resources"  
    else  
      cat = ResCategory.where(:actif => 'y', :name =>@year).first
      if cat.blank?
        flash[:message_ajax] = "Aucune ressource n'existe pour l'année '%{year}'".trn(:year => @year) 
        redirect_to :action => "show_resources"  
      else  
        init_order_where_include
        file_name = cat.export_data(@category,@user,@resource_order,@resource_include,@resource_join,@resource_where) 
        if !file_name.blank? && File.file?(file_name) 
          download_xls file_name 
        else 
          flash[:message_ajax] = "Impossible de générer le fichier Excel".trn 
          redirect_to :action => "show_resources" 
        end 
      end 
    end 
        
  end

  def show_need
    @stock, @stock_buy,@stock_after, @stock_responsible = {}, {}, {}, {}
    @stock_error = []
    @object = ResCategory.where(:name => params[:year], :parent_id => 0).first
    @object.children.each do |category|
      category.get_resources(@user).where(:stockable => 'Y').each do |resource|
        @stock["id_#{resource.id}"]=resource.quantity_left
        @stock_buy["id_#{resource.id}"]=0
      end if session[:res_category]==0 || session[:res_category]==category.id
    end

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_div', 'show_need'
        render 'shared/replace_content'
      end
    end
  end

  def show_stock
    @stock, @stock_buy,@stock_after, @stock_responsible,@needs = {}, {}, {}, {},(params[:needs]=="true"||false)
    @stock_error = []
    @object = ResCategory.where(:name => params[:year], :parent_id => 0).first
    @object.res_stocks.where(["res_stocks.es_user_id = ? or 0= ?", @user, @user]).each do |tmp_stk|
      init_stocks_hash(tmp_stk,"id_#{tmp_stk.id}")
    end
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_div', 'show_stock'
        render 'shared/replace_content'
      end
    end
  end
    
  def save_need
    check = (params[:check].presence||'Y')
    @object = ResCategory.where(:name => params[:year], :parent_id => 0).first
    @stock, @stock_buy,@stock_after, @stock_responsible = params[:stock], params[:stock_buy], params[:stock_after], params[:stock_responsible]

    @stock_error = []
    @stock.keys.each do |k|

      id = k[3..-1].to_i
  
      @stock[k]       = @stock[k].presence 

      tmp_res = ResResource.find_by_id(id)
      qty_left = @stock[k].to_i
      if tmp_res.quantity < qty_left
        @object.errors.add(:base,"La quantité restante '%{qty_left}' doit être inférieure ou égale à la quantité de départ '%{qty}' pour la ressource '%{resource}' dans la catégorie '%{cat}'.".trn(:qty_left => qty_left, :qty => tmp_res.quantity, :cat => truncate(tmp_res.res_category.description,:length => 40), :resource => truncate(tmp_res.get_description,:length => 40)))
        @stock_error << id
      end

    end unless @stock.blank?

    if @object.errors.size == 0
      if check=='N'
        @stock.keys.each do |k|
          id = k[3..-1].to_i
          tmp_res = ResResource.find_by_id(id)
          tmp_res.update_attributes(:qty_not_used => @stock[k].to_i) if tmp_res
        end unless @stock.blank?
      else
        flash[:message_ajax] = "Aucune erreur, vous pouvez sauver".trn
      end
    end
  
    @stock_error.uniq!

    respond_to do |format|
      format.js do 
        if @object.errors.size > 0 || check=='Y'
          @element_id, @partial = 'resource_div', 'show_need'
          render 'shared/replace_content'
        else
          redirect_to :action => "show_resources"
        end
      end
    end
  end


    
  def init_stock_before_op
    @object = ResCategory.where(:name => params[:year], :parent_id => 0).first
    @stock, @stock_buy,@stock_after, @stock_responsible = params[:stock], params[:stock_buy], params[:stock_after], (params[:stock_responsible]||{})
    
    @stock_error = []
    @stock.keys.each do |k|

      id = k[3..-1].to_i
  
      tmp_stk = ResStock.find_by_id(id)
      
      init_stocks_hash(tmp_stk,k)
    
      @stock[k]=tmp_stk.qty_need if @stock[k].to_i == 0
    
    end unless @stock.blank?

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_div', 'show_stock'
        render 'shared/replace_content'
      end
    end
  end

  def init_stock_after_op
    @object = ResCategory.where(:name => params[:year], :parent_id => 0).first
    @stock, @stock_buy,@stock_after, @stock_responsible = params[:stock], params[:stock_buy], params[:stock_after], (params[:stock_responsible]||{})
    
    @stock_error = []
    @stock.keys.each do |k|

      id = k[3..-1].to_i
  
      tmp_stk = ResStock.find_by_id(id)
      
      init_stocks_hash(tmp_stk,k)
    
      @stock_after[k]=tmp_stk.qty_total_not_used if @stock_after[k].to_i == 0
    
    end unless @stock.blank?

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_div', 'show_stock'
        render 'shared/replace_content'
      end
    end
  end

  def save_stock(do_save=true)
    check   = (params[:check].presence||'Y')
    @needs  = params[:needs]=="true"
    
    @object = ResCategory.where(:name => params[:year], :parent_id => 0).first
    @stock, @stock_buy,@stock_after, @stock_responsible = params[:stock], params[:stock_buy], params[:stock_after], (params[:stock_responsible]||{})

    @stock_error = []
    @stock.keys.each do |k|

      id = k[3..-1].to_i
  
      tmp_stk = ResStock.find_by_id(id)
      
      init_stocks_hash(tmp_stk,k)
    
      if do_save

        qty_buy = @stock_buy[k].to_i
  
        if @stock[k].to_i < 0
          @object.errors.add(:base,"Le stock avant OP '%{qty}' ne peut pas être négatif pour la ressource '%{product}'.".trn(:qty => @stock[k], :product => tmp_stk.res_product.name))
          @stock_error << id
        end
        if @stock_buy[k].to_i < 0
          @object.errors.add(:base,"La quantité achetée '%{qty}' ne peut pas être négative pour la ressource '%{product}'.".trn(:qty => @stock_buy[k], :product => tmp_stk.res_product.name))
          @stock_error << id
        end
        if @stock_after[k].to_i < 0
          @object.errors.add(:base,"Le stock après OP '%{qty}' ne peut pas être négatif pour la ressource '%{product}'.".trn(:qty => @stock_after[k], :product => tmp_stk.res_product.name))
          @stock_error << id
        end
  #        if tmp_stk.qty_real(@stock[k],@stock_buy[k]) < tmp_stk.qty_need
  #          @object.errors.add(:base,"Le stock réel '%{qty_real}' ne peut pas être inférieur aux besoins '%{qty_need}' pour la ressource '%{product}'.".trn(:qty_real => tmp_stk.qty_real(@stock[k],@stock_buy[k]), :qty_need => tmp_stk.qty_need, :product => tmp_stk.res_product.name))
  #          @stock_error << id
  #        end
      end
    end unless @stock.blank?

    if do_save
      if @object.errors.size == 0
        if check=='N'
          @stock.keys.each do |k|
            id = k[3..-1].to_i
            tmp_stk = ResStock.find_by_id(id)
            tmp_stk.update_attributes(:quantity => @stock[k].to_i, :quantity_added => @stock_buy[k].to_i, :qty_not_used => @stock_after[k].to_i, :es_user_id => @stock_responsible[k]) if tmp_stk
          end unless @stock.blank?
        else
          flash[:message_ajax] = "Aucune erreur, vous pouvez sauver".trn
        end
      end
      @stock_error.uniq!
    end  

    respond_to do |format|
      format.js do 
        if @object.errors.size > 0 || check=='Y'
          @element_id, @partial = 'resource_div', 'show_stock'
          render 'shared/replace_content'
        else
          redirect_to :action => "show_resources"
        end
      end
    end
  end
    
  def show_needs
    params[:needs]='true'
    save_stock(false)
  end

  def hide_needs
    params[:needs]='false'
    save_stock(false)
  end


  def product_new
    
    @needs = params[:needs]
    @object = ResProduct.new
    @object1 = {:quantity => 0}

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_div', 'new_edit_product'
        render 'shared/replace_content'
      end
    end
  end

  def product_edit
    @needs = params[:needs]
    stock = ResStock.find_by_id(params[:id])
    @object = stock.res_product
    @object1 = {:quantity => stock.quantity}

    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_div', 'new_edit_product'
        render 'shared/replace_content'
      end
    end
  end

  def product_save
    cat_year = ResCategoryYear.find_by_name(@year)
    @needs = params[:needs]
    id          = params[:id]
    
    if id
      @object = ResProduct.find_by_id(id)
    else  
      @object = ResProduct.new
    end
    new_record  = @object.new_record?

    @object.attributes = params[:object]
    @object1 = params[:object1]
    
    if @object.valid?
      
      flash[:message_ajax] = new_record ? "Création réussie".trn : "Modification réussie".trn
      @object.save(validate: false)
      @object.reload
      init_current_category
      @object.res_stocks.where(:res_category_id => cat_year.id).first.update_attribute("quantity",@object1[:quantity])
      redirect_to :action => "show_stock", :year => @year, :needs => @needs
    else
      respond_to do |format|
        format.js do 
          @element_id, @partial = 'resource_div', 'new_edit_product'
          render 'shared/replace_content'
        end
      end
    end
  end

  def product_delete
    @needs = params[:needs]

    st = ResStock.find_by_id(params[:id])
    flash[:message_ajax] = "Suppression réussie de '%{product}'".trn(:product => st.res_product.name)
    st.res_product.destroy
    st.destroy
    redirect_to :action => "show_stock", :year => @year, :needs => @needs
  end

  def resource_comment
    @object = params[:obj_type].classify.constantize.find(params[:id])
    
    respond_to do |format|
      format.js do 
        @element_id, @partial = 'resource_edit_div', 'new_edit_comment'
        render 'shared/replace_content'
      end
    end
  end

  def comment_save
    @object = params[:obj_type].classify.constantize.find(params[:id])

    @object.attributes = params[:object]
    @object.comment_user_date = DateTime.now.strftime("%d/%m/%Y %H:%M:%S") + ' ' + current_user.complete_name
    
    if @object.valid?
      flash[:message_ajax] = "Commentaire attaché".trn
      @object.save(validate: false)
      @object.reload
      init_current_category
      redirect_to :action => "show_resources" 
    else
      respond_to do |format|
        format.js do 
          @element_id, @partial = 'resource_edit_div', 'new_edit_comment'
          render 'shared/replace_content'
        end
      end
    end
  end

  private
  
  def init_stocks_hash(tmp_stk,k)
    @stock[k]       = @stock[k].presence 
    @stock_buy[k]   = @stock_buy[k].presence 
    @stock_after[k] = @stock_after[k].presence 
    @stock_responsible[k] ||= (tmp_stk.es_user ? tmp_stk.es_user_id : 0)
    @stock[k]             ||= tmp_stk.quantity||0
    @stock_buy[k]         ||= tmp_stk.quantity_added||0
    @stock_after[k]       ||= tmp_stk.qty_not_used||0
  end
  
  def init_current_category
    res_cat_year = ResCategory.where(:actif => 'y', :name =>@year).first
    if res_cat_year
      product_ids = []
      res_cat_year.res_stocks.each do |s|
        product_ids << s.res_product_id unless s.res_product_id.blank? 
      end
      product_ids.uniq!
      
      ResProduct.all.each do |p|
        unless product_ids.include?(p.id)
          ResStock.create(:res_product_id => p.id, :res_category_id => res_cat_year.id, :quantity => 0, :quantity_added => 0, :qty_not_used => 0, :es_user_id => current_user ? current_user.id : 0)
        end
      end
    end
    
    @res_categories = res_cat_year ? res_cat_year.children.select{|cat| [0,-1].include?(@category) || cat.id==@category} : []

    init_order_where_include
    
  end

  def init_order_where_include
    @resource_order,@resource_include,@resource_join,@resource_where=[],[],[],[""]
    (1..3).each do |i|
      tmp_field = @res_sort["field#{i}"]
      tmp_order = @res_sort["order#{i}"].presence || "ASC"
      case tmp_field
        when "PR"
          @resource_order << "res_priorities.sequence #{tmp_order}"
          @resource_include << :res_priority
        when "ST"
          @resource_order << "res_statuses.sequence #{tmp_order}"
          @resource_include << :res_status
        when "WHO"
          @resource_order << "es_users.name #{tmp_order}, es_users.firstname #{tmp_order}"
          @resource_include << :es_user
        when "WHEN"
          @resource_order << "res_when_starts.sequence #{tmp_order}"
          @resource_join << "INNER JOIN res_whens res_when_starts ON [LOCAL_TABLE].res_when_start_id = res_when_starts.id"         
        when "UNTILWHEN"  
          @resource_order << "res_when_ends.sequence #{tmp_order}"
          @resource_join << "INNER JOIN res_whens res_when_ends ON [LOCAL_TABLE].res_when_end_id = res_when_ends.id"         
        when "SEQUENCE"  
          @resource_order << "[LOCAL_TABLE].sequence #{tmp_order}"
      end
    end
    (1..4).each do |i|
      tmp_sign  = @res_where["sign#{i}"].presence || "="
      tmp_value = @res_where["value#{i}"]
      unless tmp_value.blank?
        @resource_where[0] += " AND " unless @resource_where[0].blank?
        @resource_where << tmp_value
        case i
          when 1 #priorite
            @resource_where[0] += "([LOCAL_TABLE].res_priority_id #{tmp_sign} ?)"
          when 2 #status
            @resource_where[0] += "([LOCAL_TABLE].res_status_id #{tmp_sign} ?)"
          when 3 #quand
            @resource_where[0] += "([LOCAL_TABLE].res_when_start_id #{tmp_sign} ?)"
          when 4 #pour quand 
            @resource_where[0] += "([LOCAL_TABLE].res_when_end_id #{tmp_sign} ?)"
        end
      end
    end

    @resource_order   = @resource_order.join(', ') unless @resource_order.empty?
    @resource_include = @resource_include.uniq     unless @resource_include.empty?

   
  end

  
  def init_filter
    param_year = params[:filter].present? && params[:filter][:year].present? ? params[:filter][:year] : (session[:res_year] || "") 
    param_year = nil unless ResCategoryYear.where(:name => param_year, :parent_id => 0).first
    @year = param_year
    session[:res_year] = @year

    param_category = params[:filter].present? ? (params[:filter][:category].presence || 0) : (session[:res_category] || 0)
    @category = param_category.to_i 
    session[:res_category] = @category
    

    param_user = params[:filter].present? ? (params[:filter][:user].presence || 0) : (session[:res_user] || 0)
    @user = param_user.to_i 
    session[:res_user] = @user
    
    @res_sort = params[:sort].present? ? params[:sort] : (session[:res_sort] || {})
    session[:res_sort] = @res_sort
    
    @res_where = params[:where].present? ? params[:where] : (session[:res_where] || {})
    session[:res_where] = @res_where
    
    #@multi_action = params[:multi_action].present? ? params[:multi_action] : {}    
    
    @copy_multiple_where = params[:copy_multiple_where].present? ? params[:copy_multiple_where] : ''
    
  end

#  def init_user
#    (session[:res_user]= (EsUser.current_user ? EsUser.current_user.id : 0)) if self.request.format== 'text/html'
#  end

end
