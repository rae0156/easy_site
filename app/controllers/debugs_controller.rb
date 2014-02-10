class DebugsController < ApplicationController
  
# necessary for non login users
skip_before_filter :login_required

  def index 
    tmp_text = "" 
    tmp_format = params[:format_debug]||""

    init_debug_param(params[:debug])

    unless @selected_model.blank?
      if tmp_format=='help'
        tmp_text +=@selected_model.constantize.cross_table(:help)
      elsif tmp_format=='refresh'
        tmp_text +=""
      elsif tmp_format=='relation'
        tmp_text +=@selected_model.constantize.cross_table(:filter =>@selected_filter,:level => @selected_level)
      elsif tmp_format=='setup'
        tmp_text +=@selected_model.constantize.cross_table(:show_setup => true,:filter =>@selected_filter,:level => @selected_level)
      elsif tmp_format=='setupfile'
        tmp_text +=@selected_model.constantize.cross_table(:setup_file => true,:filter =>@selected_filter,:level => @selected_level)        
      elsif tmp_format=='exemple'
        instance = @selected_model.constantize.find(:first) unless @selected_model.blank?
        if instance.blank?
          tmp_text +="No record exist for '#{@selected_model}'"   
        else  
          tmp_text +=instance.cross_table(:level => @selected_level)   
        end
      else  
        
        tmp_conditions = {}
        unless @selected_field.blank?
          if @selected_value.include? "*"
            tmp_conditions = ["UPPER(#{@selected_field}) LIKE UPPER(?)","#{@selected_value.gsub('*','%')}"] 
          else
            tmp_conditions[@selected_field.to_sym]=@selected_value 
          end
        end
        instance = @selected_model.constantize.find(:first,:conditions => tmp_conditions) unless @selected_model.blank?
        if instance.blank?
          tmp_text +="No record found with this selection"   
        else  
          tmp_text += case tmp_format
                      when "fixture" 
                        instance.cross_table(:format => "fixture",:level => @selected_level)
                      when "yaml"   
                        instance.cross_table(:format => "YML",:level => @selected_level)
                      else
                        instance.cross_table(:level => @selected_level)
                      end
        end
      end
    end


#==================================================================================================
#    tmp_text += Fund.cross_table(:help)
#    tmp_text += Fund.cross_table("help")        
#    tmp_text += Fund.cross_table
#    tmp_text += tmp_fund.cross_table(:root => "fund")        
#    tmp_text += Nav.cross_table(:filter => ["Nav", "NavDetail", "User"])
#    tmp_text += Fund.cross_table(:filter => ["Nav", "NavDetail", "User"])
#    tmp_text += Fund.cross_table(:filter => ["Nav", "NavDetail", "User"],:generator => true)
#    tmp_text += tmp_fund.cross_table
#    tmp_user = User.find_by_id(102)
#    tmp_text += tmp_user.cross_table    
#    tmp_text += tmp_user.cross_table(:class => true)    
#==================================================================================================

  
    @textdebug = tmp_text    
    
    respond_to do |format|
      format.html {
        render :layout => false
      } # Do nothing, so Rails will render the view debug.rhtml
    end  
  end

private

  def init_debug_param(tmp_param)
      Dir.glob("#{Rails.root}/app/models/*.rb").sort.each { |file| require_dependency file }
      @selected_model = ""
      @selected_filter = ""
      @selected_field = ""
      @selected_value = ""
      @selected_level = "5"
      unless tmp_param.blank?
        @selected_model   = tmp_param[:model]||""
        @selected_filter  = tmp_param[:filter]||""
        @selected_field   = tmp_param[:field]||""
        @selected_value   = tmp_param[:value]||""
        @selected_level   = tmp_param[:level]||"5" 
      end
      
      tmp_models = [] 
      @selected_model.constantize.reflect_on_all_associations.each do |elem|
        begin
          tmp_class = @selected_model.constantize.reflect_on_association(elem.name).klass
        rescue
          tmp_class = nil
        end
          
        unless tmp_class.nil? then
          tmp_models << tmp_class.to_s
        end
      end unless @selected_model.blank?
      tmp_models_list = tmp_models.uniq.sort.join(", ") 
      @tmp_models=tmp_models    
      
      tmp_fields = [] 
      @selected_model.constantize.columns.each do |elem|
        tmp_fields << elem.name 
      end unless @selected_model.blank?
      @tmp_fields=tmp_fields
      
      @selected_filter = @selected_filter.select{|elem| !elem.blank?} unless @selected_filter.blank?    
end
  
end

