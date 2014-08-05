# encoding: UTF-8

class EsModulesController < ApplicationController
  
  
  def list
    sorting :default => 'es_modules.module_name'
    session[:conditions_module] = create_conditions
    @modules = EsModule.paginate :per_page => 20, :page => params[:page], :order => @sort, :conditions => session[:conditions_module],:group => "es_modules.module_name"

    respond_to do |format|
      format.html {} # Do nothing, so Rails will render the view list.rhtml
      format.js do 
        @element_id, @partial = 'module_div', 'list'
        render 'shared/replace_content'
      end
    end
  end
  
  def setup
    module_name = params[:name].presence||''
    @module= EsModule.get_module(module_name)
  end
  
  def update
    module_name = params[:generated].present? ? params[:generated][:module_name].presence : "" 
    EsModule.save_setup(module_name, params[:generated]) if params[:generated].present?
    redirect_to :action => "setup",:name => module_name
  end
  
private

  def create_conditions

    conditions = []

    unless params[:global_search].blank?
      conditions.empty? ? conditions = [''] : conditions[0] += ' and '   
      conditions[0] += '(UPPER(es_modules.module_name) LIKE UPPER(?))' 
      conditions << "%#{params[:global_search]}%"
    end


    return conditions
    
  end
  
   
end
