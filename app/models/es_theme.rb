# encoding: UTF-8

class EsTheme < ActiveRecord::Base

  has_many :es_pages

  acts_as_dynamic_model([
                      {:name              => "code",
                       :column_name       => "Code",
                       :field_key         => false,
                       :mandatory         => true
                      }, 
                      {:name              => "file",
                       :column_name       => "Fichier",
                       :mandatory         => true
                      } 
                      ],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Thème".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.code
  end


  def self.change_theme(new_theme)
    theme_from = EsTheme.find_by_file(Rails.application.config.current_theme)
    theme_to = EsTheme.find_by_code(new_theme)
    current_template = EsTemplate.find_by_name(Rails.application.config.current_template)
    EsPage.where(:es_theme_id => theme_from.id, :es_template_id => current_template.id).each do |page|
      page.update_attribute(:es_theme_id,theme_to.id)
    end if theme_from
    
    EsPage.all.each do |page|
      page.update_attribute(:es_theme_id,theme_to.id) if page.es_template_id == current_template.id && page.es_theme.blank?
    end
    Rails.application.config.current_theme = theme_to.file
  end

  
  def self.load_themes
    tmp_dir = File.join(Rails.root,"app","assets","stylesheets","themes")
    Dir.entries(tmp_dir).each do |file|
      if File.file?(File.join(tmp_dir, file)) && File.extname(file)=='.css'
        EsTheme.create(:file => file, :code => File.basename(file,'.css')) unless EsTheme.find_by_file(file)
      end
    end
    self.all.each do |t|
      t.destroy unless File.file?(File.join(tmp_dir, t.file)) 
    end
  end

end