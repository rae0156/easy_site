# encoding: UTF-8

class ActionUsersController < ApplicationController

  has_es_interface_controllers

  has_actions_detect([:addon_parameter], [:execute])

  def list
    sorting :default => 'action_users.name'    
    @action_users = ActionUser.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => create_conditions,:group => "action_users.name"

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'action_div', 'list'
        render 'shared/replace_content'
      end
    end
  end

  def new
    @action_user = ActionUser.new   
    @type=@action_user.action_type_id
    @param=nil
  end
  
  def create
    @action_user = ActionUser.new(params[:action_user])
    @type=@action_user.action_type_id
    @param=params[:action_user_param]
    if @action_user.save
      @action_user.save_params(@param)
      flash[:notice] = "L'action '%{name}' a été créé.".trn(:name => @action_user.name)
      redirect_to :action => :list
    else
      render :action  => 'new'
    end
  end
  
  def refresh_params
    @type = params[:ajax_param][:action_user][:action_type_id]
    @param=nil
    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'action_user_param_div', 'action_user_param'
        render 'shared/replace_content'
      end
    end
  end
  
  def edit
    id = params[:id]
    @action_user = ActionUser.find_by_id(id)
    @type=@action_user.action_type_id
    
    tmp_params = {}
    @action_user.action_user_params.each do |p|
      tmp_params[p.action_type_param.name]=p.value unless p.action_type_param.blank?
    end
    @param=tmp_params

  end

  def update
    id = params[:id]
    @action_user = ActionUser.find_by_id(id)
    @type=@action_user.action_type_id
    @param=params[:action_user_param]
    if @action_user.update_attributes(params[:action_user]) 
      @action_user.save_params(@param)
      flash[:notice] = "L'action '%{name}' a été correctement modifié.".trn(:name => @action_user.name)
      redirect_to :action => :list
    else
      render :action => 'edit'
    end
  end

  def destroy
    tmp_element_error = ActionUser.new
    tmp = ActionUser.find(params[:id])
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "Action '%{name}' : %{error}.".trn(:name => tmp.name, :error => tmp_error))
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "L'action '%{name}' a correctement été supprimé.".trn(:name => name)
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end


  def export_csv
    sorting :default => 'action_users.name'   
    contents = ActionUser.find :all, :conditions => create_conditions, :order => @sort
    file_name = "action_users_export.csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Nom".trn,"Description".trn,"Utilisateur".trn]
       contents.each do |t|
          csv << [t.name,t.description,t.user_name]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end



  def execute
    id            = params[:action_user][:id]
    @action_user = ActionUser.find_by_id(id)
    if @action_user
      action,parameters=@action_user.get_action_and_parameters
      #puts "ici 10 : #{action.inspect}"
      #puts "ici 20 : #{parameters.inspect}"

      begin
          object_class = action[:name].constantize
      rescue 
      end
  
      if action[:type]== "BASE" || class_exists?(action[:name].to_s)
        case action[:type]
        when "CLASS"
          object_class.send(action[:action],parameters)
          flash[:notice] = "Action '[%{type}] %{controller}:%{action}' exécutée avec success".trn(:type => action[:type], :controller => action[:name],:action => action[:action])   
        when "INSTANCE"
          object_class.new.send(action[:action],parameters)
          flash[:notice] = "Action '[%{type}] %{controller}:%{action}' exécutée avec success".trn(:type => action[:type], :controller => action[:name],:action => action[:action])   
        when "BASE"
          return if send(action[:action], parameters)
          flash[:error] = "Une erreur est apparue lors de l'exécution de l'action '[%{type}] %{action}'. '%{info}' manquant(s)".trn(:type => action[:type],:action => action[:action],:info => @missed_field.join(','))   
        else
          flash[:error] = "Cette action '[%{type}] %{controller}:%{action}' ne peut être exécutée".trn(:type => action[:type], :controller => action[:name],:action => action[:action])   
        end     
      else
          flash[:error] = "Cette action '[%{type}] %{controller}:%{action}' ne peut être exécutée".trn(:type => action[:type], :controller => action[:name],:action => action[:action])   
      end
    else
      flash[:error] = "L'action demandée n'existe pas".trn   
    end
    
    redirect_to :root   
  end

  def setup_actions
    @setup = true
    @current_user_id = current_user.id
    render :action => "custom_actions"
  end

  def custom_actions
    @current_user_id = current_user.id
  end

  def save_custom
    ActionScreen.destroy_all(:user_id => current_user.id)
    params[:icons].each do |k,icon|
      id = (icon[:id].presence || "user_action_0").gsub('user_action_',"")
      ActionScreen.create({:action_user_id => id, :user_id => current_user.id, :x => icon[:left].gsub("px",""), :y => icon[:top].gsub("px","")})
    end if params[:icons].present?
    render :nothing => true
  end

private  

  #action dispo pour le module
  def my_actions(options)
    @setup = false
    get_template_part("custom_used","action_users",true)
  end


  ####################
  #  actions de base #
  ####################

  def send_mail_message(parameters={})
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:subject,:to,:message])).blank?
    MessageMailer.send_mail_message(parameters).deliver
    redirect_to :root   
    true
  end

  def send_mail(parameters={})
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:layout_name,:subject,:to,:message])).blank?
    layout_name      = parameters.delete(:layout_name)
    MessageMailer.send_mail_layout(layout_name,parameters).deliver
    redirect_to :root   
    true
  end

  def redirect(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:action,:controller])).blank?
    tmp_action      = parameters.delete(:action)
    tmp_controller  = parameters.delete(:controller)
    redirect_to :controller => tmp_controller, :action=> tmp_action, :parameters => parameters
    true    
  end
  
  def go_to_url(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:url])).blank?
    url = (parameters[:url].starts_with?("http://") || parameters[:url].starts_with?("https://") ? "" : "http://") + parameters[:url]
    redirect_to url 
    true    
  end

  def image(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file,:mode])).blank?
    case parameters[:mode]
    when "SHOW"
      file = parameters[:file]
      file = file[6..-1] if file.starts_with?("public")
      redirect_to file 
    when "GET"  
      send_file parameters[:file], :type => 'image/jpeg', :disposition => 'attachment'
    end
    true
  end

  def word(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file])).blank?
    send_file parameters[:file], :type => 'application/msword', :disposition => 'attachment'
    true
  end

  def excel(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file])).blank?
    send_file parameters[:file], :type => 'application/vnd.ms-excel', :disposition => 'attachment'
    true
  end

  def pdf(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file,:mode])).blank?
    case parameters[:mode]
    when "SHOW"
      file = parameters[:file]
      file = file[6..-1] if file.starts_with?("public")
      redirect_to file 
    when "GET"  
      send_file parameters[:file], :type => 'application/pdf', :disposition => 'attachment'
    end
    true
  end

  def text(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file,:mode])).blank?
    case parameters[:mode]
    when "SHOW"
      file = parameters[:file]
      file = file[6..-1] if file.starts_with?("public")
      redirect_to file 
    when "GET"  
      send_file parameters[:file], :type => 'text/txt', :disposition => 'attachment'
    end
    true
  end

  def video(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file,:mode])).blank?
    case parameters[:mode]
    when "SHOW"
      file = parameters[:file]
      file = file[6..-1] if file.starts_with?("public")
      redirect_to file 
    when "GET"  
      send_file parameters[:file], :disposition => 'attachment'
    end
    true
  end

  def sound(parameters={}) 
    return false unless (@missed_field = ActionUser.must_have_params(parameters,[:file,:mode])).blank?
    case parameters[:mode]
    when "SHOW"
      file = parameters[:file]
      file = file[6..-1] if file.starts_with?("public")
      redirect_to file 
    when "GET"  
      send_file parameters[:file], :type => 'audio', :disposition => 'attachment'
    end
    true
  end






  def create_conditions

    conditions = ["(user_id in (?))",[0,(current_user.blank? ? 0 : current_user.id)]]

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(action_users.name) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
    end


    return conditions
    
  end

end
