# encoding: UTF-8

class DynPagesController < DynamicController

  has_es_interface_controllers
  
  def initialize()
    @setup_controller={:delete_multi => false,:instance_name => 'Pages dynamiques'}
    @columns_screen = []
    super
  end 

  def page
    @dyn_page = DynPage.find(:first,:conditions => ["name=? and page_type = 'page'",params['name'].presence||''])
    render "dyn_parts/_part"
  end


private  

  def get_part(options)
    @dyn_page = DynPage.find(:first,:conditions => ["name=? and page_type = 'part'",options['name'].presence||''])
    get_template_part("part","dyn_parts",true)
  end


end
