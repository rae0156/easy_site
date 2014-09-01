# encoding: UTF-8

class EsContentsController < ApplicationController

  def list
    sorting :default => 'es_contents.name, es_content_details.sequence'
    session[:conditions_content] = create_conditions
    @contents = EsContentDetail.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_content], :include => :es_content

    respond_to do |format|
      format.html {} 
      format.js do 
        @element_id, @partial = 'content_div', 'list'
        render 'shared/replace_content'
      end
    end
  end

  def move_up
    id = params[:id]
    content_detail = EsContentDetail.find_by_id(id)
    content_detail.update_attribute('sequence',content_detail.sequence - 1.5)
    content_detail.es_content.compress_detail
    redirect_to :action => "list" 
  end
  
  def move_down
    id = params[:id]
    content_detail = EsContentDetail.find_by_id(id)
    content_detail.update_attribute('sequence',content_detail.sequence + 1.5)
    content_detail.es_content.compress_detail
    redirect_to :action => "list" 
  end

  def new
    @from_action = "new"
    @content = EsContentDetail.new(:sequence => 1)    
  end
  
  def add
    @from_action = "add"
    id = params[:id]
    tmp_content = EsContentDetail.find_by_id(id)
    @content = EsContentDetail.new(:es_content_id => tmp_content.es_content_id, :sequence => tmp_content.sequence + 1)
    render :action  => 'new'
  end
  
  def create
    @from_action = params[:from_action]
    name = params[:content].delete(:name)
    @content = EsContentDetail.new(params[:content])
    @content.content  = ""
    @content.editable = EsContent::EDITABLE_CONTENT_TYPES.include?(@content.content_type) ? "Y" : "N"
    content = EsContent.find_by_name(name)
    if content
      @content.es_content_id = content.id
    else
      @content.es_content = EsContent.new(:name => name)
    end
    
    if @content.save
      flash[:notice] = "Le contenu '%{name}' a été créé.".trn(:name => @content.name)
      redirect_to :action => :list
    else
      render :action  => 'new'
    end
  end
  
  def edit
    id = params[:id]
    @content = EsContentDetail.find_by_id(id)
  end

  def update
    id = params[:id]
    @content = EsContentDetail.find_by_id(id)
    if EsContent.find(:first,:conditions => ["id <> ? AND name = ?",@content.es_content.id,params[:content][:name]])
      @content.errors.add(:name, "#Ce nom de contenu '%{name}' existe déjà.".trn(:name => params[:content][:name])) 
    end

    @content.attributes = params[:content]
    @content.valid? if @content.errors.empty?

    if @content.errors.empty? 
      @content.es_content.save
      flash[:notice] = "Le contenu '%{name}' a été correctement modifié.".trn(:name => @content.name)
      redirect_to :action => :list
    else
      render :action => 'edit'
    end
  end

  def destroy
    tmp_element_error = EsContentDetail.new
    tmp = EsContentDetail.find(params[:id])
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, "Contenu '%{name}' : %{error}.".trn(:name => tmp.name, :error => tmp_error))
        end
      else
        content = EsContent.find_by_name(name)
        if content
          if content.es_content_details.size == 0
            content.destroy
          else
            content.compress_detail
          end 
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = "Le contenu '%{name}' a correctement été supprimé.".trn(:name => name)
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end


  def export_csv
    sorting :default => 'es_contents.name, es_content_details.sequence'
    contents = EsContentDetail.find :all, :conditions => session[:conditions_template], :order => @sort, :include => :es_content
    file_name = "contents_export.csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv << ["Nom du contenu".trn,"Séquence".trn,"Editable".trn,"Type de contenu".trn,"Utilisé".trn]
       contents.each do |t|
          csv << [t.es_content.name,t.sequence.to_i,t.editable,t.content_type,t.used? ? "Y" : "N"]
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end


  def design_content
    @content_detail_id = params[:id]
    contentdetail = EsContentDetail.find(@content_detail_id)
    if contentdetail
      @content_tiny = contentdetail.content
      @content_detail_text = "#{contentdetail.name.humanize} : #{contentdetail.content_detail_name}"
    else
      redirect_to :action => "list"
    end
  end

  def setup_module
    @contentdetail = EsContentDetail.find(params[:id])
    @module_action_name = @contentdetail.module_action_name.split(' ')
    @contentdetail.create_module_params(EsModule.get_module_params(@module_action_name[0],@module_action_name[1]))
  end

  def update_setup_module
    EsContentDetail.find(params[:id]).save_module_params(params[:generated]) if params[:generated].present?
    flash[:notice] = "Les paramètres ont été sauvés.".trn
    redirect_to :action => "setup_module",:id => params[:id]
  end

private

  def create_conditions

    conditions = []

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += "(UPPER(es_contents.name) LIKE UPPER(?))"
      conditions << "%#{params[:global_search]}%"
    end


    return conditions
    
  end

end
