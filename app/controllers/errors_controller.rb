# encoding: UTF-8

class ErrorsController < ActionController::Base

  layout 'application'
  include AuthenticatedSystem   
   
  def custom_error
    @exception = env['action_dispatch.exception']
    @status_code = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code

    respond_to do |format|
      format.html do 
          if ["ActionController::RoutingError","ActionController::UnknownAction","AbstractController::ActionNotFound"].include?(@exception.class.name)
            redirect_to :controller => "sites", :action => "error", :error => "L'adresse '%{url}' n'est pas reconnue".trn(:url => request.env['REQUEST_URI']), :format => :post
          else
            session[:custom_error]=true
            render "sites/custom_error", status: @status_code, layout: !request.xhr? 
          end
      end
      format.xml { render xml: details, root: "error", status: @status_code }
      format.json { render json: {error: details}, status: @status_code }
    end
  end
   
  protected
   
  def details
    @details ||= {:name => @exception.class.name, :status_code => @status_code, :message => @exception.message, :trace => @exception.backtrace.join("<BR>").html_safe}
  end
  helper_method :details
 
end
