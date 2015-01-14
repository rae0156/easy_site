# encoding: UTF-8

class EsTheme < ActiveRecord::Base

  has_many :es_pages

  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => { },
                  :model_audit_label  => "Thème".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.code
  end
  
  def self.load_themes
    tmp_dir = File.join(Rails.root,"app","assets","stylesheets","themes")
    Dir.entries(tmp_dir).each do |file|
      if File.file?(File.join(tmp_dir, file)) && File.extname(file)=='.css'
        EsTheme.create(:file => file, :code => File.basename(file,'.css')) unless EsTheme.find_by_file(file)
      end
    end
    
  end

end