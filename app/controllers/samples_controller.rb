# encoding: UTF-8

class SamplesController < ApplicationController

  has_es_interface_controllers

  @@default_sort    = 'name' 
  @@param_name      = "element"  #ne pas modifier, dans les vues, mettre element comme instance dans text_field, etc...
  @@model           = EsTask
  @@msg_creation    = 'Cette tâche a été correctement créée.'.trn
  @@msg_update      = 'Cette tâche a été correctement modifiée.'.trn
  @@msg_delete      = 'Cette tâche a correctement été supprimée.'.trn
  @@field_print     = ["name","description","sequence"]
  @@name_print      = ["Nom","Description","Séquence"]
  @@condition_info  = ['(UPPER(es_tasks.name) LIKE UPPER(?) OR UPPER(es_tasks.description) LIKE UPPER(?))',2]
  
  def list
    sorting :default => @@default_sort
    session[:conditions] = create_conditions
    @collections = @@model.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions]
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
    @element = @@model.new()
  end
   
  # Save the Setup to database -
  def create
    @element = @@model.new(params[@@param_name.to_sym])
    if @element.save
      flash[:notice] = @@msg_creation.trn
      redirect_to :action => "list"
    else
      render :action => 'new'
    end
  end
  
  # display the selected Setup
  def edit
    id = params[:id].presence || 0 
    @element = @@model.find(id)
  end
  
  # Update the Setup in the database -
  def update
    @element = @@model.find_by_id(params[:id])
    if @element.update_attributes(params[@@param_name.to_sym])
      flash[:notice] = @@msg_update.trn
      redirect_to :action => "list"
    else
      render :action => 'edit'
    end
  end
  
  # Delete the Setup from database -
  def destroy
    tmp_element_error = @@model.new
    tmp = @@model.find(params[:id])
    if tmp
      name = tmp.name
      unless tmp.destroy
        tmp.errors.full_messages.each do |tmp_error| 
          tmp_element_error.errors.add(:base, tmp_error)
        end
      end
    end
    if tmp_element_error.errors.empty? 
      flash[:notice] = @@msg_delete.trn
    else
      flash[:errors_destroy] = tmp_element_error
    end
    redirect_to :action => "list"
  end

  # setups export to csv
  def export_csv
    # Find all Setup with the stored restrictions
    sorting :default => @@default_sort
    collection = @@model.find :all, :order => @sort, :conditions => session[:conditions]
    # Creation of the file
    file_name = "#{@@param_name}_export_" + current_user.id.to_s + ".csv"
    
    csv_string = CSV.generate({:col_sep => ';', :encoding => "ISO-8859-15" }) do |csv|
       csv <<  @@name_print.map{|n| n.trn}
       collection.each do |element|
          csv << @@field_print.map{|f| element[f]}
        end
    end
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv; charset=iso-8859-1; header=present'
  end

private

  def create_conditions

    conditions = []

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += @@condition_info[0] 
      @@condition_info[1].times do |i|
        conditions << "%#{params[:global_search]}%"
      end
    end


    return conditions
    
  end

end
