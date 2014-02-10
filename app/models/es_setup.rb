# encoding: UTF-8

class EsSetup < ActiveRecord::Base
  acts_as_tree :order => "name"

  belongs_to :es_category
  
  attr_accessible :name, :value, :type_data, :read_only, :path, :nbr_element, :possible_values
  
  validates_presence_of :name, :message => 'Le nom est obligatoire'
  validates_presence_of :type_data, :message => 'Le type est obligatoire'
  validates_uniqueness_of :path , :scope => [:name], :message => "Ce paramétrage existe déjà"
  
  
  def self.get_setup(setup_name,default="")
    tmp_setup = self.find(:first, :conditions => ["name = ?", setup_name] )
    return tmp_setup.blank? ? default : tmp_setup.value
  end

  def validate
    tmp_err = false
    tmp_complement = ""
    case self.type_data
      when "date"
        tmp_err = !self.value.is_a_valid_date?
      when "heure"
        tmp_err = !self.value.is_a_valid_time?
      when "numéro"
        tmp_decimal = self.possible_values.to_s.is_numeric? ? self.possible_values.to_i : 0
        tmp_complement = " avec #{tmp_decimal} décimale(s)"
        if !self.value.is_numeric?
          tmp_err = true
        else
          self.value = self.value.to_f.to_s
          if self.value.split('.').to_a.count == 2 && self.value.split('.').last.size > tmp_decimal
            tmp_err = true
          else
            tmp_err = false
            self.value = tmp_decimal == 0 ? self.value.to_i : self.value.to_f
          end
        end        
    end
    errors.add_to_base "La valeur doit être de type '#{self.type_data}#{tmp_complement}'" if tmp_err
  end

  def self.arbo(dir)
    
    temp_branchs = self.find :all, :order => "path", :conditions => ["path LIKE ?", "#{dir[0...-1]}%"]
    branchs = []
    temp_branchs.each do |temp_branch|
      if temp_branch.path.split('/').count >= (dir).split('/').count + 1
        branchs << temp_branch.path.split('/')[(dir).split('/').count]
      end
    end
    branchs = branchs.uniq

    temp_setups = self.find :all, :order => "name", :conditions => ["path = ?", "#{dir[0...-1]}"]
    setups = []
    temp_setups.each do |temp_setup|
      setups << temp_setup.name
    end
    setups = setups.uniq

    
    return [branchs,setups]
  end


end