# encoding: UTF-8

class EsUsersController < ApplicationController
  
 before_filter :login_required, :except => ["login", "login_connect", "logout", "new_user", "create", "confirm", "password_lost", "password_recovery","confirm_mail"]
   
  # Load the pages -
  def list
    sorting :default => 'es_users.name asc, es_users.firstname asc'
    
    if(!params[:query].blank?)
      conditions = ["UPPER(es_users.name) LIKE UPPER(?) OR UPPER(es_users.firstname) LIKE UPPER(?) OR UPPER(es_users.mail) LIKE UPPER(?)", 
                  "%#{params[:query]}%",
                  "%#{params[:query]}%",
                  "%#{params[:query]}%"
                  ] 
    else
      conditions = []
    end
    
    session[:conditions] = conditions
    
    @users = EsUser.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => conditions

    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'user_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  #Create an empty user in order to be used in the user new screen -
  def new
    @user = EsUser.new()
  end
   
  # Save the User to database -
  def create_complete
    @user = EsUser.new(params[:user])
    @user.active = generate_activation_code(16)
    @user.tempo_password = @user.password1
    @user.password = @user.password1

    @user.active = 'N'
    if @user.save
      flash[:notice] = "Cet utilisateur a été correctement créée. Vous pouvez maintenant l'activer, le modifier et lui donner des accès.".trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected user
  def edit
    id = params[:id].nil? ? params[:cid][0] : params[:id]
    @user = EsUser.find_by_id(id)
    @roles        = EsRole.find :all, :order => 'description'
  end
  
  # Update the user in the database -
  def update
    @user = EsUser.find_by_id(params[:id])
    mail = send_mail_activation(@user, params[:user][:active])
    @user.special_action="update" 
    @roles        = EsRole.find :all, :order => 'description'
    
    params[:user][:es_role_ids] = []  if params[:user].blank? || !params[:user].include?(:es_role_ids) && !EsUser.current_user.id == params[:id]
    if @user.update_attributes(params[:user])
      @user.update_attribute(:password, @user.password1) unless @user.password1.blank? 
      flash[:notice] = 'Cet utilisateur a été correctement modifiée.'.trn
      send_mail_activation(@user, '[mail]') if mail
      redirect_to :action => "list"
    else
      render :action => 'edit'
    end
  end
  
  # Delete the user from database -
  def destroy

    tmp_element_error = EsUser.new
    for id in params[:cid]
      tmp = EsUser.find(id)
      if tmp.mail == EsUser.current_user.mail
        flash[:error] = "Vous ne pouvez pas vous supprimer vous-même.".trn 
      else
        unless tmp.destroy
          tmp.errors.full_messages.each do |tmp_error| 
            tmp_element_error.errors.add(:base, "Utilisateur '%{mail}' : %{error}. Il a été désactivé".trn(:mail => tmp.mail, :error => tmp_error))
          end
          tmp.update_attribute(:active, "N")   
        end
      end
    end
    
    if tmp_element_error.errors.empty? 
      flash[:notice] = 'Utilisateur(s) correctement supprimé(s).'.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  # Delete the user from database -
  def activation
    tmp = EsUser.find(params[:id])
    if tmp.mail == EsUser.current_user.mail       
      flash[:error] = "Vous ne pouvez pas vous désactiver vous-même".trn  
    else
      mail = send_mail_activation(tmp, "")
      tmp.active == 'Y' ? tmp.update_attribute(:active, "N") : tmp.update_attribute(:active, "Y")    
      flash[:notice] = "L'utilisateur '%{user}' a été #{tmp.active == 'Y' ? 'activé' : 'désactivé'}.".trn(:user => tmp.mail)
      send_mail_activation(tmp, '[mail]') if mail
    end
    redirect_to :action => "list"
  end

  # users export to csv
  def export_csv
    # Find all user with the stored restrictions
    users = EsUser.find :all, :conditions => session[:conditions]
    # Creation of the file
    file_name = "users_export_" + current_user.id.to_s + ".csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Activé".trn,"Nom".trn,"Prénom".trn,"Mail".trn]
       users.each do |t|
          csv << [t.active,t.name,t.firstname,t.mail]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end


  def profile
    @user = EsUser.find_by_id(EsUser.current_user.id)
  end 
   
  def profile_update
    @user = EsUser.find_by_id(EsUser.current_user.id)    
    if @user.update_attributes(params[:user]) 
      flash[:notice] = "Votre profil a correctement été modifié.".trn
      redirect_to :controller => :sites, :action => :index
    else
      render :action  => 'profile'
    end     
  end
  
  def login
    session.delete(:return_to) unless flash[:return_to].present?
  end
  
  def login_connect

    user = EsUser.find_by_pseudo(params[:user][:mail].downcase) 
    if user.blank?
      mail = params[:user][:mail].downcase
      user = EsUser.find_by_mail(params[:user][:mail].downcase)
    else
      mail = user.mail
    end
    unless user.blank? 
      self.current_user = EsUser.authenticate(mail, params[:user][:password])
      if self.current_user
        if self.current_user.active == "Y"
          DataFile.create_dir("public","content", "users","#{current_user.id}") unless current_user.blank? 
          flash[:notice] = "Bonjour".trn + " #{self.current_user.firstname} #{self.current_user.name}"
          if session[:return_to].blank?
            redirect_to :controller => :sites, :action => :index
          else  
            redirect_to session[:return_to]
          end
        else
          self.current_user = nil
          flash[:error] = "L'utilisateur n'est pas actif".trn
          redirect_to :action => :login
        end
      else
        flash[:error] = "L'utilisateur ou le mot de passe est invalide".trn + "!"
        redirect_to :action => :login
      end
    else
      flash[:error] = "L'utilisateur est invalide".trn + "!"
      redirect_to :action => :login
    end
  end

  def logout
    self.current_user = nil
    reset_session
    flash[:notice] = "L'utilisateur a été déconnecté".trn "."
    redirect_to :controller => :sites, :action => :index
  end

  def new_user
    @user = EsUser.new
  end

  def create
    @user = EsUser.new(params[:user])
    @user.active = generate_activation_code(16)
    @user.tempo_password = @user.password1
    @user.password = @user.password1
    EsRole.create({:name => 'user', :description => 'Utilisateur'}) unless EsRole.find_by_name("user")

    if @user.save
      @user.es_roles.push EsRole.find_by_name("user")
      UserMailer.validation_new_user(@user,request.protocol + request.host_with_port).deliver
      flash[:notice] = "L'utilisateur '%{mail}' a été créé. Un mail vient de lui être envoyé.".trn(:mail => @user.mail)
      redirect_to :controller => :sites, :action => :index
    else
      render :action  => 'new_user'
    end
  end


  def password
    @user = EsUser.find_by_id(EsUser.current_user.id)
    @user.oldpassword=""
    @user.password=""
    @user.password1=""
    @user.password2=""
  end

  def password_update
    @user = EsUser.find_by_id(EsUser.current_user.id)    

    if @user.update_attributes(params[:user]) 
      @user.update_attribute(:password, @user.password1)
      @user.tempo_password = @user.password1
      UserMailer.new_psw_user(@user).deliver
      flash[:notice] = "Le mot de passe de l'utilisateur '%{mail}' a été modifié. Un mail vous a été envoyé.".trn(:mail => @user.mail)
      redirect_to :controller => :sites, :action => :index
    else
      @user.oldpassword=""
      @user.password=""
      @user.password1=""
      @user.password2=""
      render :action  => 'password'
    end     
  end
  
  def mail
    @user = EsUser.find_by_id(EsUser.current_user.id)
    @user.newmail=""
  end

  def mail_update
    @user = EsUser.find_by_id(EsUser.current_user.id)    
    params[:user][:newmail].strip!
    if @user.update_attributes(params[:user]) 
      @user.update_attribute("activemail", generate_activation_code(16))
      UserMailer.mail_change_instructions(@user, request.protocol + request.host_with_port).deliver
      UserMailer.mail_change_instructions(@user).deliver
      flash[:notice] = "La demande de changement de mail '%{mail}' est enregistrée. Un mail vous a été envoyé.".trn(:mail => @user.newmail)
      redirect_to :controller => :sites, :action => :index
    else
      @user.newmail=""
      render :action  => 'mail'
    end     
  end

  def confirm_mail
      user = EsUser.find_by_activemail(params[:id])    
      unless user.blank?
        UserMailer.activation_new_mail(user,'mail').deliver
        UserMailer.activation_new_mail(user,'newmail').deliver
        user.update_attributes({:mail => user.newmail,:newmail => "", :activemail => ""})
        flash[:notice] = "Votre nouvelle adresse mail '%{mail}' est maintenant active.".trn(:mail => user.mail)
      else
        flash[:error] = "Aucun utilisateur ne correspond à cette activation de mail.".trn
      end
      redirect_to :controller => :sites, :action => :index
  end
  
  def confirm
      user = EsUser.find_by_active(params[:id])    
      unless user.blank?
        user.update_attribute(:active, "Y")
        UserMailer.confirm_new_user(user).deliver
        user.update_attribute(:tempo_password, "")
        flash[:notice] = "L'inscription de '%{mail}' est validée.".trn(:mail => user.mail)
      else
        flash[:error] = "Aucun utilisateur ne correspond à cette validation.".trn
      end
      redirect_to :controller => :sites, :action => :index
  end
 
  def password_lost
    @user = EsUser.new #just for errors
  end
  
  def password_recovery
    user = EsUser.find_by_mail(params[:user][:mail])    
    unless user.blank?
      tmp_password = generate_activation_code(6)
      user.update_attribute(:password, tmp_password)
      UserMailer.password_reset_instructions(user,tmp_password).deliver
      flash[:notice] = "Un mail vous a été envoyé à l'adresse '%{mail}'.".trn(:mail => user.mail)
      redirect_to :controller => :sites, :action => :index    
    else
      flash[:error] = "Aucun utilisateur ne correspond à ce mail.".trn
      render :action  => 'password_lost'
    end
  end

private

  def send_mail_activation(user, activation)
    unless activation == "[mail]"
      tmp_mail = user.active == 'N' && (activation.blank? || activation != 'N')
      return tmp_mail
    else
      tmp_password=''
      if user.password_hash.blank?
        tmp_password = generate_activation_code(6)
        user.update_attribute(:password, tmp_password)
      elsif !user.tempo_password.blank?
        tmp_password = user.tempo_password
        user.update_attribute(:tempo_password, "")
      end
      UserMailer.activation_user(user, tmp_password).deliver
      flash[:notice] += " Un mail vient d'être envoyé à l'utilisateur.".trn
    end
    
  end
  
end
