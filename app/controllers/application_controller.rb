# encoding: UTF-8
require 'iconv'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  protect_from_forgery
  include Userstamp

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Vous n'êtes pas autorisé à accéder à cette page"
    redirect_to root_url 
  end

  private

  def current_ability
    @current_ability ||= Ability.new(current_es_user)
  end
  
  # Builds up @sort based upon what the user has sent in params[:sort]
  def sorting(options = {})
    options[:default] ||= 'created_at DESC'                         # handling the default value
    unless params[:sort].blank?                                     # does params[:sort] contains something at least ?
      mdata = params[:sort].scan(/(?:(\S+)(_reverse)$)|(?:(\S+)$)/) # applying the regexp
      unless mdata.nil?                                             # if it returned something
        mdata = mdata[0]                                            # we retrieving the match items array
        @sort = (mdata[0].nil? ? mdata[2] : "#{mdata[0]} DESC")     # and it initializes @sort with what has matched
      end
    end                                                             # if ever it hasn't been initialized
    @sort ||= options[:default]                                     # @sort is filled with the default value
    

  end


  # ----------------------------
  # Download the generated PDF -
  # ----------------------------
  def download_pdf(pdf, displayed_filename)
    send_data pdf.render, :filename => displayed_filename
  end  

  def download_csv(csv_string, file_name)
    
    send_data Iconv.conv('iso-8859-1//IGNORE', 'utf-8', csv_string), :filename => file_name, :disposition => 'attachment', :type => 'text/csv;charset=utf-8;header=present'
#    send_data csv_string, :filename => file_name, :disposition => 'attachment', :type => 'text/csv;charset=utf-8;header=present'
  end  

end
