class EsSession < ActiveRecord::SessionStore::Session 
  
  belongs_to :es_user 
  before_save :ensure_user_is_set 
  
  
  def self.find_by_session_id(session_id) 
    find(:first,:conditions => ["session_id = ?",session_id]) 
  end 
  
  private 
  def ensure_user_is_set 
    warden_data = self.data["warden.user.es_user.key"] 
    if warden_data 
      user_id = warden_data[0][0] 
      self.es_user = EsUser.find(user_id) 
    end 
  end 
end 