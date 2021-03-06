# encoding: UTF-8

class EsSetup < ActiveRecord::Base

  belongs_to :es_category
  
  acts_as_dynamic_model([
                      {:name              => "name",
                       :column_name       => "Name",
                       :field_key         => false,
                       :mandatory         => true
                      }, 
                      {:name              => "type_data",
                       :column_name       => "Type",
                       :mandatory         => true
                      }, 
                      {:name              => "path",
                       :column_name       => "Chemin",
                       :field_key         => true,
                       :field_key_scope   => "name"
                      } 
                      ],{:audit_model=>false}) 
 
  acts_as_audited :keep_text          => true,
                  :child_attrs => {:es_category => :name },
                  :model_audit_label  => "Paramétrage".trn,
                  :process_label      => "Changement manuel".trn
 
  # it is an example, but not necessary if you have a field called 'ISO','CODE' or 'NAME'
  def get_audit_label
    self.name
  end
  
  def self.get_setup(setup_name,default="")
    tmp_setup = self.find(:first, :conditions => ["name = ?", setup_name] )
    return (tmp_setup.blank? || tmp_setup.value.nil?) ? default : tmp_setup.value
  end

  def self.set_setup(setup_name,value="")
    tmp_setup = self.find(:first, :conditions => ["name = ?", setup_name] )
    unless tmp_setup
      self.create(:value => value, :path => "resource/paramétrage", :name => setup_name, :type_data => "text", :read_only => "N")
    else
      tmp_setup.update_attribute("value",value)
    end
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
        tmp_complement = " " + "avec %{nbr_decimale} décimale(s)".trn(:nbr_decimale => tmp_decimal)
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
    errors.add "base", "La valeur doit être de type '%{type_donnee}'".trn(:type_donnee =>"#{self.type_data}#{tmp_complement}") if tmp_err
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