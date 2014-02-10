# encoding: UTF-8

class EsFonction < ActiveRecord::Base

  belongs_to :es_category

  def self.execute(fonction_code)
    fonction = self.find_by_code(fonction_code)
    return fonction.blank? ? "" : fonction.execute
  end

  def execute
    case self.code
    when "current"
        return '#'
    end    
  end

end