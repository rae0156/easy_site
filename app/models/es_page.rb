# encoding: UTF-8

class EsPage < ActiveRecord::Base

  belongs_to :es_template
  belongs_to :es_theme
  
  acts_as_dynamic_model([{:name => "action",
                          :field_key => true,
                          :field_key_scope => "controller",
                          :mandatory => true},
                         {:name => "controller",
                          :mandatory => true}
                      ])

  def self.find_page(controller,action)
    pages = EsPage.where(:controller => controller,:action=> action)
    pages = EsPage.where(:controller => controller,:action=> "[ALL]") if pages.blank?
    pages = EsPage.where(:controller => "[ALL]",:action=> "[ALL]") if pages.blank?
    pages ? pages[0] : nil
  end


  def self.must_sign?(controller,action)
    page = self.find_page(controller,action)
    return page ? page.signed=='Y' : true
  end
  

end