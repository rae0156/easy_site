# encoding: UTF-8

class MenusController < ApplicationController

  has_es_interface_controllers
  
  def setup_side
    redirect_to :controller => "menu_sides", :action => "list"
  end

  def setup_navigation
    redirect_to :controller => "menu_navigations", :action => "list"
  end

  def setup_dropdown
    redirect_to :controller => "menu_dropdowns", :action => "list"
  end

  def setup_vertical
    redirect_to :controller => "menu_verticals", :action => "list"
  end

  def setup_sheet
    redirect_to :controller => "menu_sheets", :action => "list"
  end

  def setup_horizontal
    redirect_to :controller => "menu_horizontals", :action => "list"
  end


private  

  def get_menu_sidebar(options)
    @menu = EsMenu.find(:first,:conditions => ["name=? and link_type = 'side'",options['code_menu'].presence||''])
    get_template_part("menu","menus",true)
  end

  def get_menu_navigation(options)
    @menu = EsMenu.find(:first,:conditions => ["name=? and link_type = 'navigation'",options['code_menu'].presence||''])
    get_template_part("menu","menus",true)
  end

  def get_menu_dropdown(options)
    @menu = EsMenu.find(:first,:conditions => ["name=? and link_type = 'dropdown'",options['code_menu'].presence||''])
    get_template_part("menu","menus",true)
  end

  def get_menu_vertical(options)
    @menu = EsMenu.find(:first,:conditions => ["name=? and link_type = 'vertical_menu'",options['code_menu'].presence||''])
    get_template_part("menu","menus",true)
  end

  def get_menu_sheet(options)
    @menu = EsMenu.find(:first,:conditions => ["name=? and link_type = 'sheet'",options['code_menu'].presence||''])
    get_template_part("menu","menus",true)
  end

  def get_menu_horizontal(options)
    @menu = EsMenu.find(:first,:conditions => ["name=? and link_type = 'horizontal'",options['code_menu'].presence||''])
    get_template_part("menu","menus",true)
  end

end
