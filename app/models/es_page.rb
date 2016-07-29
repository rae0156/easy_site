# encoding: UTF-8

class EsPage < ActiveRecord::Base

  belongs_to :es_template
  belongs_to :es_theme
  
  acts_as_dynamic_model([{:name => "action",
                          :field_key => true,
                          :field_key_scope => "controller",
                          :link_update => true,
                          :column_name => "Action",
                          :column_text => "[ALL] = toutes les actions",
                          :label_name => "Action",
                          :mandatory => true },
                         {:name => "es_theme_id",
                          :column_name => 'Thême',
                          :label_name => 'Thême',
                          :model_linked_field => 'code' },
                         {:name => "controller",
                          :column_name => 'Controlleur',
                          :column_text => "[ALL] = tous les controlleurs",
                          :label_name => 'Controlleur',
                          :mandatory => true },
                         {:name => "es_template_id",
                          :column_name => 'Template',
                          :label_name => 'Template' ,
                          :model_linked_field => 'name' },
                         {:name => "flag_admin",
                          :display_list => false,
                          :column_name => 'Administrateur?',
                          :label_name => 'Administrateur?' },
                         {:name => "flag_connection",
                          :display_list => false,
                          :column_name => 'Affichage de la connexion',
                          :label_name => 'Affichage de la connexion' },
                         {:name => "signed",
                          :display_list => false,
                          :column_name => "Besoin d'être connecté",
                          :label_name => "Besoin d'être connecté" },


                        ],{:audit_model=>false})
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_template => :name ,:es_theme => :code},
                  :model_audit_label  => "Droits controlleur".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.controller + " " + self.action
  end

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