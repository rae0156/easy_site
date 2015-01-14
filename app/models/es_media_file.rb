# encoding: UTF-8

class EsMediaFile < ActiveRecord::Base


  belongs_to :es_category
  acts_as_dynamic_model([],{:audit_model=>false}) 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Média".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end
  
  def self.get_code_citation
    EsMediaFile.where(:media_type => 'citation').all.map{|element| element.name}.uniq
  end

  def self.get_code_address
    EsMediaFile.where(:media_type => 'address').all.map{|element| element.name}.uniq
  end

  def self.get_code_alert
    EsMediaFile.where(:media_type => 'alert').all.map{|element| element.name}.uniq
  end

  def self.get_code_blog
    EsMediaFile.where(["media_type = ? and parent_id is null","blog"]).all.map{|element| element.name}.uniq
  end

  def self.get_code_breadcrumb
    EsMediaFile.where(["media_type = ? and parent_id is null","breadcrumb"]).all.map{|element| element.name}.uniq
  end

  def self.get_code_carousel
    EsMediaFile.where(["media_type = ? and parent_id is null","carousel"]).all.map{|element| element.name}.uniq
  end

  def self.get_code_collapse
    EsMediaFile.where(["media_type = ? and parent_id is null","collapse"]).all.map{|element| element.name}.uniq
  end

  def self.get_code_imagelist
    EsMediaFile.where(["media_type = ? and parent_id is null","image_list"]).all.map{|element| element.name}.uniq
  end

  def self.get_code_video
    EsMediaFile.where(:media_type => 'video').all.map{|element| element.name}.uniq
  end

end