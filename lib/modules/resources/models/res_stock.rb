# encoding: UTF-8
class ResStock < ActiveRecord::Base
  has_es_interface_models
  acts_as_multi_site
  
  belongs_to :res_category
  belongs_to :es_user
  belongs_to :res_product


  attr_accessible :res_category_id,:quantity,:quantity_added,:qty_not_used,:es_user_id,:res_product_id

  validates_presence_of :quantity,          :message => '#' + "La quantité est obligatoire".trn
  validates_numericality_of :quantity,      :message => '#' + "La quantité doit être numérique et supérieure à zéro".trn, :allow_nil => true
  validates_presence_of :quantity_added,    :message => '#' + "La quantité achetée est obligatoire".trn
  validates_numericality_of :quantity_added,:message => '#' + "La quantité achetée doit être numérique et supérieure à zéro".trn, :allow_nil => true
  validates_presence_of :qty_not_used,      :message => '#' + "La quantité restante est obligatoire".trn
  validates_numericality_of :qty_not_used,  :message => '#' + "La quantité restante doit être numérique et supérieure à zéro".trn, :allow_nil => true
  validates_presence_of :es_user_id,        :message => '#' + "La personne responsable est obligatoire".trn


  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Stock".trn,
                  :process_label      => "Changement manuel".trn
  
  def qty_total_not_used
    total = 0
    self.res_category.children.each do |c|
      c.res_resources.each do |r|
        if r.res_product_id==self.res_product_id
          if r.stockable=='Y' 
            total += r.qty_not_used||0
          else
            total += r.quantity||0
          end
        end
      end
    end
    total
  end

  def need_exist?        
    return self.res_product.res_resources.size > 0    
  end

  def qty_need
    total = 0
    self.res_category.children.each do |c|
      c.res_resources.each do |r|
        if r.res_product_id==self.res_product_id
          total += r.quantity||0
        end
      end
    end
    total
  end

  def qty_to_buy(qty,need)
    need.to_i < qty.to_i ? 0 : (need.to_i - qty.to_i)
  end

  def qty_real(qty,bought)
    (qty||0).to_i + (bought||0).to_i 
  end


end
