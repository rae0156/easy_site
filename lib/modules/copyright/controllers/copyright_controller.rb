# encoding: UTF-8

class CopyrightController < ApplicationController

  has_es_interface_controllers
  

  def get_credit
    
    @credit_text = self.class.get_module_setup("setup/admin/specific","credit_text","").gsub(/\n/,"<BR>")
    
  end


private  
  def get_right(options)
    year_to   = Date.today.year
    year_from = options["start_year"].presence || year_to
    company   = options["company_name"].presence || ""
    message   = options["message"].presence || ""    
    message   = " : #{message}" unless message.blank?
    
    format    = "<div class='row'><div class='col-md-12'><div class='text-center'>%{text}</div></div></div>"
    text =  "<p>&copy; #{company} #{year_from}-#{year_to}#{message}</p>"
    return format % {:text => text}
  end
  

end
