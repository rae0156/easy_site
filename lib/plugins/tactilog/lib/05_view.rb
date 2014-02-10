rails_env = (ENV['RAILS_VERSION'].blank? ? Rails::VERSION::STRING : ENV['RAILS_VERSION'])[0]

class TactilogController < ActionController::Base
  def index
    
    rails_env = (ENV['RAILS_VERSION'].blank? ? Rails::VERSION::STRING : ENV['RAILS_VERSION'])[0]
    @selected_model = !params[:tactilog_help].blank? && !params[:tactilog_help][:model].blank? ? params[:tactilog_help][:model] : ""
    @selected_model_log = !params[:tactilog_help].blank? && !params[:tactilog_help][:model_log].blank? ? params[:tactilog_help][:model_log] : ""
    
    text = []

    Dir.glob("#{Rails.root}/app/models/*.rb").sort.each { |file| require_dependency file }


    text << "<!DOCTYPE html>                                                                        "
    text << "<html lang='en'>                                                                                                                                               "
    text << "  <HEAD>                                                                                                                                                      "
    text << "    <title>Tactilog & CrossTable</title>                                                                                                                    "
    text << "    <meta name='viewport' content='width=device-width, initial-scale=1.0'> "
    text << "    <link href='http://getbootstrap.com/2.3.2/assets/css/bootstrap.css' rel='stylesheet'>                                                                   "
    text << "    <link href='http://getbootstrap.com/2.3.2/assets/css/bootstrap-responsive.css' rel='stylesheet'>                                                                   "
    text << "  </HEAD>                                                                                                                                                     "
    text << "  <BODY>                                                                                                                                                      "
    text << "    <div class='navbar navbar-inverse navbar-fixed-top'>                                                                                                     "
    text << "      <div class='navbar-inner'>                                                                                                                            "
    text << "        <div class='container'>                                                                                                                             "
    text << "          <p class='brand'>Tactilog & CrossTable (Rails 2 & 3) <small>plugged in " + Rails.root.to_s.split('/').last + "</small></p>                                                                                                        "
    text << "        </div>                                                                                                                                              "
    text << "      </div>                                                                                                                                                "
    text << "    </div>                                                                                                                                                  "
    text << "    <div class='container'>                                                                                                                                 "
    text << "      <div class='hero-unit'>                                                                                                                              "
    text << "        <h2>Quick help</h2>                                                                                                                                "
    text << "        <BR>                                                                                                                                               "
    text << "        <p>First time you launch your application after installing Tactilog, a setup file 'tactilog.yml' is created into your '/config' directory.<BR>     "
    text << "         If you have the time, open and have a look to it.</p>                                                                                           "
    text << "        <P>The goal of Tactilog is the easy creation of line in one or more log files.<BR>                                                                 "
    text << "         This is configurable by environment, model or controller.</p>                                                                                   "
    text << "        <P>The goal of CrossTable is to permit to retreive every fields, datas and table relations from a model.<BR>                                       "
    text << "         It is drived by a setup file 'cross_table.yml'.</p>                                                                                             "
    text << "      </div>                                                                                                                                               "
    text << "    </div>                                                                                                                                                  "
    text << "    <div class='container'>                                                                                                                                 "
    text << "      <div class='alert alert-info'>                                                                                                                     "
    text << "        <h3>How to use Tactilog : </h3>                                                                                                            "
    tmp_text = LogYamlSetup.help_text.gsub(10.chr,'<BR>').gsub('  ','&nbsp;&nbsp;') 
    tmp_text = tmp_text.html_safe if rails_env=='3'
    text << "        <p>" + tmp_text + "</p>"
    text << "      </div>                                                                                                                                           "
    
    text << "      <HR>                                                                                                                                              "
    text << "    <div class='row'>                                                                                                                                   "
    text << "      <div class='span12'>                                                                                                                             "
    text << "        <H2>'Tactilog' sample</H2>                                                                                                               "
    text << "        <form action='tactilog' method='post'>                                                                                                     "
    text << "          <fieldset>                                                                                                                              "
    text << "            <P><%= select('tactilog_help', 'model_log', ActiveRecord::Base.send(:subclasses).collect(&:name).sort_by{|e| e},:selected => @selected_model_log )%> </p>"    
    text << "            <P><input class='btn btn-primary' name='commit' type='submit' value='Test a model' /><P>                                "
    text << "          </fieldset>                                                                                                                             "
    text << "        </form>                                                                                                                                     "
    text << "      </div>                                                                                                                                          "
    text << "    </div>                                                                                                                                            "

    unless @selected_model_log.blank?
      tmp_message = @selected_model_log.constantize.log
      text << "    <div class='row'>                                                                                                                                   "
      text << "      <div class='span12'>                                                                                                                             "
      text << "        <div class = 'thumbnail'>                                                                                                                   "
      text << "          <h4> " + @selected_model_log + " has been logged. You can see the text below in the log file into '/log'</h4>"       
      tmp_text = tmp_message.gsub(10.chr,'<BR>').gsub('  ','&nbsp;&nbsp;')
      tmp_text = tmp_text.gsub('<%=','&lt;%=')
      tmp_text = tmp_text.html_safe if rails_env=='3'
      # tmp_text = tmp_text.html_safe if rails_env=='3'
      text << "          <CODE> " + tmp_text + "</CODE>"       
      text << "        </div>                                                                                                                                      "
      text << "      </div>                                                                                                                                          "
      text << "    </div>                                                                                                                                            "
    end
    text << "      <HR>                                                                                                                                              "

    text << "      <div class=' alert alert-info'>                                                                                                                    "
    text << "        <h3>How to use CrossTable : </h3>                                                                                                              "
    tmp_text = ActiveRecord::Base.cross_table(:help).gsub(10.chr,'<BR>').gsub('  ','&nbsp;&nbsp;')
    tmp_text = tmp_text.html_safe if rails_env=='3'
    text << "        <p>" + tmp_text + "</p>"
    text << "      </div>                                                                                                                                             "
    text << "      <HR>                                                                                                                                              "

    
    text << "    <div class='row'>                                                                                                                                   "
    text << "      <div class='span6'>                                                                                                                             "
    text << "        <H2>'Cross Table' sample</H2>                                                                                                               "
    text << "        <form action='tactilog' method='post'>                                                                                                     "
    text << "          <fieldset>                                                                                                                              "
    text << "            <P><%= select('tactilog_help', 'model', ActiveRecord::Base.send(:subclasses).collect(&:name).sort_by{|e| e},:selected => @selected_model )%> </p>"    
    text << "            <P><input class='btn btn-primary' name='commit' type='submit' value='Test a model' /><P>                                "
    text << "          </fieldset>                                                                                                                             "
    text << "        </form>                                                                                                                                     "
    text << "      </div>                                                                                                                                          "

    if @selected_model.blank?
      text << "      <div class='span6'>                                                                                                                             "
      text << "      </div>                                                                                                                                          "
      text << "    </div>                                                                                                                                            "
    else
      
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
      end
      tmp_models_list = tmp_models.uniq.sort.join(", ") 
      tmp_models << @selected_model
      tmp_models = tmp_models.map{|elem| "'" + elem + "'"}.join(",") 

      text << "      <div class='span6'>                                                                                                                             "
      text << "        <H3 style='text-align: left;'>Relations for " + @selected_model + "</H3>                                                                                  "
      text << "        <P>" + tmp_models_list + "</P>"       
      text << "      </div>                                                                                                                                          "
      text << "    </div>                                                                                                                                            "
      text << "    <HR>                                                                                                                                              "


      text << "    <div class='row'>                                                                                                                                   "
      text << "      <div class='span6'>                                                                                                                             "
      text << "        <div class = 'thumbnail'>                                                                                                                   "
      text << "          <H3 style='text-align: left;'>Linked tables for " + @selected_model + "</H3>                                                                          "
      text << "          <CODE><%= " + @selected_model + ".cross_table(:filter => [" + tmp_models + "]).gsub(10.chr,'<BR>').gsub('  ','&nbsp;&nbsp;')" + (rails_env=='3' ? ".html_safe" : "") + "%></CODE>"       
      text << "        </div>                                                                                                                                      "
      text << "      </div>                                                                                                                                          "
      text << "      <div class='span6'>                                                                                                                             "
      text << "        <div class = 'thumbnail'>                                                                                                                   "
      text << "          <H3 style='text-align: left;'>Setup for " + @selected_model + "</H3>                                                                                  "
      text << "          <CODE><%= " + @selected_model + ".cross_table(:filter => [" + tmp_models + "], :show_setup => true).gsub(10.chr,'<BR>').gsub('  ','&nbsp;&nbsp;')" + (rails_env=='3' ? ".html_safe" : "") + "%></CODE>"       
      text << "        </div>                                                                                                                                      "
      text << "      </div>                                                                                                                                          "
      text << "    </div>                                                                                                                                            "

    end  
    
    text << "     </div>                                                                                                                                                "
    text << "   </BODY>                                                                                                                                                   "
    text << "</HTML>                                                                                                                                                        "

#     render(:layout => 'application', :inline => text.join("<BR>"))
     render(:inline => text.join(13.chr))
  end

  
end

if rails_env == '3'
#  RailsTemplate::Application.routes.draw do
#      match 'tactilog' => 'tactilog#index'
#      match 'tactilog/index' => 'tactilog#index'
#  end
else
  #avoid the clear before creating new root
  class << ActionController::Routing::Routes;self;end.class_eval do
    define_method :clear!, lambda {}
  end
  
  
  ActionController::Routing::Routes.draw do |map|
      map.connect "tactilog", :controller => 'tactilog', :action => 'index'
      map.connect "tactilog/index", :controller => 'tactilog', :action => 'index'
  end

end

