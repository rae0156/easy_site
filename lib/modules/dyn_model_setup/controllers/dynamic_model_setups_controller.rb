# encoding: UTF-8

class DynamicModelSetupsController < ApplicationController

  has_es_interface_controllers


  def list_model
    
    sorting :default => 'dynamic_model_setups.model_name'
    session[:conditions_setup] = create_conditions
    @models = DynamicModelSetup.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_setup]


    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'dyn_model_div', 'list'
        render 'shared/replace_content'
      end
    end
  end

  alias_method :list, :list_model

  def setup_a_model
    @model = DynamicModelSetup.find_by_id(params[:id])
  end
  
  def update_setup_model
    @model = DynamicModelSetup.find_by_id(params[:id])

    values = params["generated"].presence || {}
    dyn_att_list = DynamicModelFieldSetup.dynamic_attribute_list
    @model.dynamic_model_field_setups.each do |field|
      upd_attrs = {}
      dyn_att_list.each do |att|
        params_field_name = "#{field.field_name}_#{att}"
        if values[params_field_name].present?
          value = values[params_field_name].presence
          upd_attrs[att.to_sym] = value
        end
      end
      field.update_attributes(upd_attrs)
      field.errors.full_messages.each do |msg|
        @model.errors.add("base", "Colonne '%{col}' ".trn(:col => field.field_name) + " : " + msg)
      end
    end

    if @model.errors.full_messages.count == 0
      flash[:notice] = 'Ce modèle a été correctement modifié.'.trn
      @model.reinit_dynamic_model_from_setup
      redirect_to :action => "list_model"
    else
      render :action => 'setup_a_model'
    end
  end


  def reinit_setup_model
    @model = DynamicModelSetup.find_by_id(params[:id])
    reload = @model.reinit_model    
    if reload
      flash[:notice] = 'Le modèle %{model} a été réinitialisé.'.trn(:model => @model.model_name)
    else
      flash[:notice] = "Les paramétrages du modèle %{model} ont été supprimés. Il est préférable de redémarrer l'application.".trn(:model => @model.model_name)
    end
    redirect_to :action => "list_model"
  end

private

  def create_conditions

    conditions = []

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(dynamic_model_setups.model_name) LIKE UPPER(?) OR UPPER(dynamic_model_setups.label) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
      conditions << "%#{params[:global_search]}%"
    end

    return conditions
    
  end

end
