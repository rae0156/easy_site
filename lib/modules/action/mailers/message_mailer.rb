# encoding: UTF-8
class MessageMailer < ActionMailer::Base
   
    has_es_interface_mailers
   
    def send_mail_message(params={})
      mail_params,other_params=get_params(params)
      return if mail_params.blank?
      @message = other_params[:message].presence || "<<<#{Time.now}>>>"
      mail( mail_params ) 
    end

    def send_mail_layout(layout_name,params={})
      mail_params,other_params=get_params(params)
      return if mail_params.blank?
      @parameters = other_params
      mail( mail_params )   do |format|
        format.html { render layout_name }
      end
    end

private

  def get_params(options={})
    mail_params={}
    if options[:to].present?
      mail_params[:subject]   = options[:subject].present?  ? options.delete(:subject) : "/"
      mail_params[:from]      = options[:from].present?     ? options.delete(:from)    : 'noreply@nosite.com'
      mail_params[:to]        = options.delete(:to)
      mail_params[:date]      = options[:date].present?     ? options.delete(:date) : Time.now
      mail_params[:cc]        = options.delete(:cc)         if options[:cc].present?
      mail_params[:bcc]       = options.delete(:bcc)        if options[:bcc].present?
      
    end
    return mail_params,options
  end
end