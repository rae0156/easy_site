# encoding: UTF-8

class EsContentDetailElementArticle < ActiveRecord::Base
  set_table_name "es_content_detail_elements" 
  has_dyn_attr(:table_attribute_type => 'es_attribute_types', :table_attribute => 'es_attributes')  

  validate :validate_date
  
  def self.get_roles
    EsRole.all.map{|r| [r.name,r.id]}
  end

  def validate_date

      if !self.date_from.blank? && !self.date_to.blank? 
        if self.date_from.to_datetime > self.date_to.to_datetime
          errors.add("base","#" + "La date/heure de départ doit être avant la date/heure d'arrivée".trn)
        end    
      end
      
      if !self.role.blank? && self.connected=='N'
        errors.add("base","#" + "Vous devez cocher 'Connecté' si des rôles sont sélectionnés".trn)
      end
      
  end

  def is_visible?
    
    tmp_date_from     = self.date_from.blank? ? Time.zone.now : Time.zone.parse(self.date_from,"%d/%m/%Y %H:%M:%S")
    tmp_date_to       = self.date_to.blank? ? Time.zone.now : Time.zone.parse(self.date_to,"%d/%m/%Y %H:%M:%S")
    tmp_role          = (self.role||'').split(',').map{|r| (EsRole.find_by_id(r)||EsRole.new(:name =>'')).name}
    
    visible_date      = (tmp_date_from <= Time.zone.now) && (Time.zone.now <= tmp_date_to)
    visible_connected = (self.connected=='Y' && !EsUser.current_user.blank?) || self.connected=='N'  
    visible_roles     = self.role.blank? || (!self.role.blank? && !EsUser.current_user.blank? && EsUser.current_user.role?(tmp_role))
    
    return visible_date && visible_connected && visible_roles
  end

end