# encoding: UTF-8


class ResCategory < ActiveRecord::Base
  require 'nokogiri'

  has_es_interface_models
  acts_as_multi_site

  
  has_many :res_actions
  has_many :res_evals
  has_many :res_resources
  has_many :res_stocks  

  belongs_to :responsible_a, :class_name => "EsUser", :foreign_key => "responsible_a_id"
  belongs_to :responsible_b, :class_name => "EsUser", :foreign_key => "responsible_b_id"

  acts_as_dynamic_model([
                          {:name              => "parent_id",
                           :label_name        => "Année",
                           :column_name       => "Année",
                           :display_list      => false, 
                           :order             => 1
                          },                           
                          {:name              => "name",
                           :label_name        => "Nom de la catégorie",
                           :column_name       => "Nom de la catégorie",
                           :sort              => false,
                           :field_key         => true,
                           :field_key_scope   => "parent_id",
                           :mandatory         => true,
                           :order             => 2
                          }, 
                          {:name              => "description",
                           :label_name        => "Description",
                           :column_name       => "Description",
                           :mandatory         => true,
                           :order             => 3
                          }, 
                          {:name              => "responsible_a_id",
                           :label_name        => "Responsable A",
                           :column_name       => "Responsable A",
                           :model_linked      => 'EsUser',
                           :model_linked_field=> 'complete_name',
                           :mandatory         => true,
                           :order             => 4
                          }, 
                          {:name              => "responsible_b_id",
                           :label_name        => "Responsable B",
                           :column_name       => "Responsable B",
                           :model_linked      => 'EsUser',
                           :model_linked_field=> 'complete_name',
                           :order             => 5
                          }, 
                          {:name              => "sequence",
                           :label_name        => "Séquence",
                           :column_name       => "Séquence",
                           :order             => 6
                          }, 
                        ],
                        { :only_field_defined=>true, 
                          :audit_model=>false, 
                          :fixed_attributes => {}, 
                          :dynamic_search_exists => false, 
                          :sequence_exists => true, 
                          :parent_exists => true,
                          :children_exists => true,
                          :instance_name => "Catégorie de ressources"
                        }) 
  acts_as_audited :keep_text          => true,
                  :child_attrs        => {},
                  :model_audit_label  => "Catégorie de ressources".trn,
                  :process_label      => "Changement manuel".trn


  def self.get_list_for_responsible_a_id
    EsUser.order("name, firstname").all
  end

  def self.get_list_for_responsible_b_id
    return get_list_for_responsible_a_id
  end

  def self.get_years(all=false)
    cat_years = []
    tmp_cat = all ? self : self.where(:actif => 'Y')    
    tmp_cat.all.each do |cat|
      cat_years << cat.name unless cat.parent      
    end
    cat_years
  end

  def self.get_category(year)
    cat_year = ResCategory.where(["name = ? and (parent_id = 0 or parent_id is null)",year]).first
    if cat_year
      return cat_year.children.map{|c| [c.description, c.id]}
    else
      return nil
    end
  end


  def responsible_text
    text = []
    text << responsible_a.complete_name unless responsible_a.blank?
    text << responsible_b.complete_name unless responsible_b.blank?
    return text.join(' - ')
  end

  def get_actions(user,options={})
    
    tmp_order, tmp_include, tmp_join, tmp_where = "sequence",nil,nil,nil
    options.each do |k,v|
      case k
      when :order
        tmp_order=v.gsub('[LOCAL_TABLE]',"res_actions") unless v.blank?
      when :include
        tmp_include=v unless v.nil?
      when :join
        tmp_join=v.map{|e|e.gsub('[LOCAL_TABLE]',"res_actions")} unless v.nil?
      when :where
        tmp_where=v.map{|e|e.gsub('[LOCAL_TABLE]',"res_actions")} unless v.nil?
      end
    end
    
    result = self.res_actions.order(tmp_order).includes(tmp_include).joins(tmp_join).where(tmp_where)
    result = result.where(:es_user_id => user) unless (user||0)==0
    result
  end

  def get_resources(user,options={})

    tmp_order, tmp_include, tmp_join, tmp_where, include_other_user = "res_resources.sequence",nil,nil,nil,false
    options.each do |k,v|
      case k
      when :order
        tmp_order=v.gsub('[LOCAL_TABLE]',"res_resources") unless v.blank?
      when :include
        tmp_include=v unless v.nil?
      when :include_other_user
        include_other_user =v unless v.nil?
      when :join
        tmp_join=v.map{|e|e.gsub('[LOCAL_TABLE]',"res_resources")} unless v.nil?
      when :where
        tmp_where=v.map{|e|e.gsub('[LOCAL_TABLE]',"res_resources")} unless v.nil?
      end
    end
    
    result = self.res_resources.order(tmp_order).includes(tmp_include).joins(tmp_join).where(tmp_where)
    unless (user||0)==0
      if include_other_user
        result = result.where(["res_actions.es_user_id = ? OR res_resources.es_user_id = ?",user,user]).includes(:res_action)
      else
        result = result.where(:es_user_id => user)
      end
    end
    result
  end

  def get_eval_years
    self.res_evals.select('DISTINCT year').order("year desc").map{|e| e.year}
  end

  def get_evals(year)
    self.res_evals.where(:year => year).order('sequence')
  end

  def export_data(category,user,resource_order,resource_include,resource_join,resource_where)    
    year = self.name
    file_name = ResCategory.get_export_file_name(:name => "res_#{self.name.gsub(/[^0-9A-Za-z]/, '_')}.xls", :prefix => true)    
    book = Spreadsheet::Workbook.new 

    format_header = Spreadsheet::Format.new :pattern_fg_color => "xls_color_22", 
                                            :pattern => 1, 
                                            #:align => :center, 
                                            #:horizontal_align => "center", 
                                            #:vertical_align => "center", 
                                            :size => 11                                     

    format_sub_title = Spreadsheet::Format.new :pattern_fg_color => "xls_color_20", 
                                            :color => "white", 
                                            :pattern => 1, 
                                            :align => :left, 
                                            :horizontal_align => "left", 
                                            :vertical_align => "center", 
                                            :size => 11                                     
    
    format_sub_header = Spreadsheet::Format.new :pattern_fg_color => "xls_color_20", 
                                            :color => "white", 
                                            :pattern => 1, 
                                            :align => :center, 
                                            :horizontal_align => "center", 
                                            :vertical_align => "center", 
                                            :border           => :thin,
                                            :size => 10                                     
    
    format_row    = Spreadsheet::Format.new :pattern_fg_color => "xls_color_14", 
                                            :color => "Black", 
                                            :pattern => 1, 
                                            :border           => :thin,
                                            :size => 10

    format_row_bold= Spreadsheet::Format.new :pattern_fg_color => "xls_color_14", 
                                            :color => "Black", 
                                            :pattern => 1, 
                                            :border           => :thin,
                                            :size => 10,
                                            :weight => :bold
                                            
    format_row_w   = Spreadsheet::Format.new :pattern_fg_color => "xls_color_23", 
                                            :color => "Black", 
                                            :pattern => 1, 
                                            :border           => :thin,
                                            :size => 10

    format_row_bold_w = Spreadsheet::Format.new :pattern_fg_color => "xls_color_23", 
                                            :color => "Black", 
                                            :pattern => 1, 
                                            :border           => :thin,
                                            :size => 10,
                                            :weight => :bold
                                            
    format_row1   = Spreadsheet::Format.new :pattern_fg_color => "xls_color_14", 
                                            :color => "Black", 
                                            :pattern => 2, 
                                            :size => 10,
                                            :vertical_align => "top",
                                            :border           => :thin,
                                            :text_wrap => true
                                            
    format_row2   = Spreadsheet::Format.new :pattern_fg_color => "white", 
                                            :color => "Black", 
                                            :pattern => 2, 
                                            :border           => :thin,
                                            :size => 10

    if category==-1 then
      row_id = -1
      sheet1 = book.create_worksheet :name => "Evaluations".trn
      [35,35,50,50,15,15,50].each_with_index do |w,i|
        sheet1.column(i).width = w
      end
      self.children.each do |c|
        row_id += 1
        sheet1.row(row_id).default_format = format_header 
        sheet1.row(row_id).push *[c.description, c.responsible_text]

        unless c.long_description.blank?
          row_id += 1
          row_id += 1
          sheet1.row(row_id).default_format = format_sub_title
          sheet1.row(row_id).push *["Description".trn]            
          row_id += 1
          sheet1.row(row_id).default_format = format_row1
          sheet1.row(row_id).height = 120
          sheet1.row(row_id).push *[Nokogiri::HTML(c.long_description).text.gsub(13.chr,'')] 
          sheet1.merge_cells(row_id, 0, row_id, 6)
        end
        
        evals = c.get_evals(year.to_i)
        if evals.size > 0
          row_id += 1
          row_id += 1
          sheet1.row(row_id).default_format = format_sub_title
          sheet1.row(row_id).push *["Evaluations pour l'année '%{year}'".trn(:year => year.to_i)]            
          evals.each do |e|
            row_id += 1
            sheet1.row(row_id).default_format = format_row1 
            sheet1.row(row_id).height = 80
            sheet1.row(row_id).push *[Nokogiri::HTML(e.description).text.gsub(13.chr,'')] 
            sheet1.merge_cells(row_id, 0, row_id, 6)
          end
        end

        c.get_eval_years.each do |tmp_year|
          if tmp_year != year.to_i
            evals = c.get_evals(tmp_year)
            if evals.size > 0
              row_id += 1
              row_id += 1
              sheet1.row(row_id).default_format = format_sub_title
              sheet1.row(row_id).push *["Evaluations pour l'année '%{year}'".trn(:year => tmp_year)]            
              evals.each do |e|
                row_id += 1
                sheet1.row(row_id).default_format = format_row1 
                sheet1.row(row_id).height = 80
                sheet1.row(row_id).push *[Nokogiri::HTML(e.description).text.gsub(13.chr,'')]            
                sheet1.merge_cells(row_id, 0, row_id, 6)
              end
            end
          end
        end
      end          
    elsif user!=0 then
      row_id = -1
      user_name = EsUser.find_by_id(user).complete_name
      sheet1 = book.create_worksheet :name => user_name  
      [8,8,8,50,15,15,50,50].each_with_index do |w,i|
        sheet1.column(i).width = w
      end
      self.children.each do |c|
        if c.id==category || category==0

          actions = c.get_actions(user,{:order => resource_order,:include => resource_include,:join => resource_join,:where => resource_where})
          ressources = c.get_resources(user,{:include_other_user=>true,:order => resource_order,:include => resource_include,:join => resource_join,:where => resource_where})

          next if actions.size==0 && ressources.size==0 
          
          row_id += 1
          sheet1.row(row_id).default_format = format_header 
          sheet1.row(row_id).push *[c.description, c.responsible_text]
          
          if actions.size > 0
            row_id += 1
            sheet1.row(row_id).default_format = format_sub_title
            sheet1.row(row_id).push *["Actions de %{user}".trn(:user => user_name)]            
            row_id += 1
            sheet1.row(row_id).default_format = format_sub_header 
            sheet1.row(row_id).push *["Priorité".trn,"Statut".trn,"","Description".trn,"Quand".trn,"Pour quand".trn,"Ressource(s)".trn]            
            actions.each do |a|
              row_id += 1
              sheet1.row(row_id).default_format = format_row 
              sheet1.row(row_id).push *[a.res_priority.code,a.res_status.code,"",a.description.gsub(13.chr,''),a.get_start_date,a.get_end_date,a.get_resources_text]            
            end
          end
          
          if ressources.size > 0
            row_id += 1
            sheet1.row(row_id).default_format = format_sub_title
            sheet1.row(row_id).push *["Ressources de %{user}".trn(:user => user_name)]            
            row_id += 1
            sheet1.row(row_id).default_format = format_sub_header 
            sheet1.row(row_id).push *["Priorité".trn,"Statut".trn,"Besoin".trn,"Description".trn,"Quand".trn,"Pour quand".trn,"Action".trn,"Responsable".trn]            
            ressources.each do |r|
              row_id += 1
              sheet1.row(row_id).default_format = format_row 
              who_where = r.res_product ? self.res_stocks.where(:res_product_id => r.res_product_id).first.es_user : nil
              sheet1.row(row_id).push *[r.res_priority.code,r.res_status.code,r.quantity,r.get_description.gsub(13.chr,''),r.get_start_date,r.get_end_date,r.res_action.description.gsub(13.chr,''),(r.es_user ? r.es_user.complete_name : "") + (who_where && who_where != r.es_user  ? " (chez %{user})".trn(:user=> who_where.complete_name) : "")]            
            end
          end
          
        end
      end
      row_id = -1
      sheet2 = book.create_worksheet :name => "Ressources de %{user}".trn(:user => EsUser.find_by_id(user).complete_name) 
      [50,50,15,15,15].each_with_index do |w,i|
        sheet2.column(i).width = w
      end
      self.children.each do |c|
        if c.id==category || category==0
          ressources = c.get_resources(user,{:order => resource_order,:include => resource_include,:join => resource_join,:where => resource_where})

          next if ressources.size == 0
          row_id += 1
          
          sheet2.row(row_id).default_format = format_header 
          sheet2.row(row_id).push *[c.description, c.responsible_text]
          
          if ressources.size > 0
            row_id += 1
            sheet2.row(row_id).default_format = format_sub_header 
            sheet2.row(row_id).push *["Description".trn,"Action".trn,"Besoin".trn,"Reste après OP".trn, "Se trouve chez".trn]            
            ressources.each do |r|
              row_id += 1
              sheet2.row(row_id).default_format = format_row 
              sheet2.row(row_id).push *[r.get_description.gsub(13.chr,''),r.res_action.description.gsub(13.chr,''),r.quantity, r.stockable=='Y' ? r.quantity_left : "",r.res_product ? self.res_stocks.where(:res_product_id => r.res_product_id).first.es_user.complete_name : '']            
            end
          end
          
        end
      end
    else
      sheet=[]

      sheet[0] = book.create_worksheet :name => "Récapitulatif".trn
      [20,8,8,8,50,50,15,15,200].each_with_index do |w,i|
        sheet[0].column(i).width = w
      end
      row_id_0 = -1
      row_id_0 +=1
      sheet[0].row(row_id_0).default_format = format_header 
      sheet[0].row(row_id_0).push *["Récapitulatif des actions et ressources pour l'année '%{year}'".trn(:year => year)]
      row_id_0 +=1
      sheet[0].row(row_id_0).default_format = format_sub_header 
      sheet[0].row(row_id_0).push *["Catégorie".trn,"Priorité".trn,"Statut".trn,"Besoin".trn,"Description".trn,"Qui".trn,"Quand".trn,"Pour quand".trn,"Ressource(s)".trn]            


      sheet[1] = book.create_worksheet :name => "Stock produits".trn
      [50,25,25,25,25,25,25,25,25].each_with_index do |w,i|
        sheet[1].column(i).width = w
      end
      row_id_1 = -1
      row_id_1 +=1
      sheet[1].row(row_id_1).default_format = format_header 
      sheet[1].row(row_id_1).push *["Stock des produits pour l'année '%{year}'".trn(:year => year)]
      row_id_1 +=1
      sheet[1].row(row_id_1).default_format = format_sub_header 
      sheet[1].row(row_id_1).push *["Produit".trn,"Se trouve chez".trn,"Stock avant OP".trn,"Besoin".trn,"Quantité à acheter".trn,"Quantité achetée".trn,"Stock réel".trn,"Stock après OP".trn,"Stock restant des ressources".trn]            
      self.res_stocks.each do |tmp_stk|
        row_id_1 += 1
        sheet[1].row(row_id_1).default_format = format_row 
        sheet[1].row(row_id_1).push *[tmp_stk.res_product.name,(tmp_stk.es_user ? tmp_stk.es_user.complete_name : ''),tmp_stk.quantity||0,
                                      tmp_stk.qty_need,tmp_stk.qty_to_buy(tmp_stk.quantity||0,tmp_stk.qty_need),tmp_stk.quantity_added||0,
                                      tmp_stk.qty_real(tmp_stk.quantity||0,tmp_stk.quantity_added||0),tmp_stk.qty_not_used||0,tmp_stk.qty_total_not_used]            
      end


      sheet[2] = book.create_worksheet :name => "Stock produits + détail".trn
      [50,25,25,10,10,25,75,75,75].each_with_index do |w,i|
        sheet[2].column(i).width = w
      end
      row_id_2 = -1
      row_id_2 +=1
      sheet[2].row(row_id_2).default_format = format_header 
      sheet[2].row(row_id_2).push *["Stock des produits pour l'année '%{year}' et le détail par besoin".trn(:year => year)]
      row_id_2 +=1
      sheet[2].row(row_id_2).default_format = format_sub_header 
      sheet[2].row(row_id_2).push *["Produit".trn,"Se trouve chez".trn,"Responsable".trn,"Stock réel".trn,"Besoin".trn,"Utilisateur du besoin".trn,"Ressource".trn,"Action".trn,"Catégorie".trn]            
      self.res_stocks.each do |tmp_stk|

        detail=false
        if category==0
          detail=true
        else
          detail = ResResource.where(:res_category_id =>category, :res_product_id => tmp_stk.res_product_id).first
        end

        if detail
          row_id_2 += 1
          sheet[2].row(row_id_2).default_format = format_row 
          sheet[2].row(row_id_2).push *[tmp_stk.res_product.name,(tmp_stk.es_user ? tmp_stk.es_user.complete_name : ''),"",tmp_stk.qty_real(tmp_stk.quantity||0,tmp_stk.quantity_added||0),tmp_stk.qty_need]         
          tmp_stk.res_category.children.each do |c|
            c.res_resources.each do |r|
              if r.res_product_id==tmp_stk.res_product_id #r.stockable=='Y' && 
                row_id_2 += 1
                sheet[2].row(row_id_2).default_format = format_row2 
                sheet[2].row(row_id_2).push *[tmp_stk.res_product.name,(tmp_stk.es_user ? tmp_stk.es_user.complete_name : ''),r.es_user ? r.es_user.complete_name : '',"",r.quantity||0,r.res_action.es_user ? r.res_action.es_user.complete_name : '',r.get_description.gsub(13.chr,''),r.res_action.description.gsub(13.chr,''),c.name]         
              end
            end
          end
        end

                                         
      end

      
      s_i = 2
      color_pair_impair=true
      self.children.each do |c|        
        s_i +=1
        if c.id==category || category==0
          row_id = -1
          sheet[s_i] = book.create_worksheet :name => c.name
          [8,8,8,50,50,15,15,200].each_with_index do |w,i|
            sheet[s_i].column(i).width = w
          end
  
          actions = c.get_actions(user,{:order => resource_order,:include => resource_include,:join => resource_join,:where => resource_where})
          ressources = c.get_resources(user,{:order => resource_order,:include => resource_include,:join => resource_join,:where => resource_where})

          (color_pair_impair= color_pair_impair ? false : true) if actions.size > 0 || ressources.size > 0
  
          row_id += 1
          sheet[s_i].row(row_id).default_format = format_header 
          sheet[s_i].row(row_id).push *[c.description, c.responsible_text]

          unless c.long_description.blank?
            row_id += 1
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_sub_title
            sheet[s_i].row(row_id).push *["Description".trn]            
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_row1
            sheet[s_i].row(row_id).height = 120
            sheet[s_i].row(row_id).push *[Nokogiri::HTML(c.long_description).text.gsub(13.chr,'')] 
            sheet[s_i].merge_cells(row_id, 0, row_id, 7)
          end
          
          if actions.size > 0
            row_id += 1
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_sub_title
            sheet[s_i].row(row_id).push *["Actions".trn]            
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_sub_header 
            sheet[s_i].row(row_id).push *["Priorité".trn,"Statut".trn,"","Description".trn,"Qui".trn,"Quand".trn,"Pour quand".trn,"Ressource(s)".trn]            
            actions.each do |a|
              row_id += 1
              sheet[s_i].row(row_id).default_format = format_row 
              sheet[s_i].row(row_id).push *[a.res_priority.code,a.res_status.code,"",a.description.gsub(13.chr,''),a.es_user ? a.es_user.complete_name : "",a.get_start_date,a.get_end_date,a.get_resources_text]            
              row_id_0 += 1
              sheet[0].row(row_id_0).default_format = color_pair_impair ? format_row : format_row_w
              sheet[0].row(row_id_0).push *[c.name,a.res_priority.code,a.res_status.code,"",a.description.gsub(13.chr,''),a.es_user ? a.es_user.complete_name : "",a.get_start_date,a.get_end_date,a.get_resources_text]
              sheet[0].row(row_id_0).set_format(4, color_pair_impair ? format_row_bold : format_row_bold_w) if a.res_resources.size>0          
            end
          end
  
          if ressources.size > 0
            row_id += 1
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_sub_title
            sheet[s_i].row(row_id).push *["Ressources".trn]            
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_sub_header 
            sheet[s_i].row(row_id).push *["Priorité".trn,"Statut".trn,"Besoin".trn,"Description".trn,"Responsable".trn,"Quand".trn,"Pour quand".trn]            
            ressources.each do |r|
              who_where = r.res_product ? self.res_stocks.where(:res_product_id => r.res_product_id).first.es_user : nil
              row_id += 1
              sheet[s_i].row(row_id).default_format = format_row 
              sheet[s_i].row(row_id).push *[r.res_priority.code,r.res_status.code,r.quantity,r.get_description.gsub(13.chr,''),(r.es_user ? r.es_user.complete_name : "") + (who_where && who_where != r.es_user  ? " (chez %{user})".trn(:user=> who_where.complete_name) : ""),r.get_start_date,r.get_end_date]            
              row_id_0 += 1
              sheet[0].row(row_id_0).default_format = color_pair_impair ? format_row : format_row_w 
              sheet[0].row(row_id_0).push *[c.name,r.res_priority.code,r.res_status.code,r.quantity,r.get_description.gsub(13.chr,''),(r.es_user ? r.es_user.complete_name : "") + (who_where && who_where != r.es_user  ? " (chez %{user})".trn(:user=> who_where.complete_name) : ""),r.get_start_date,r.get_end_date]            
            end
          end
  
  
          evals = c.get_evals(year.to_i)
          if evals.size > 0
            row_id += 1
            row_id += 1
            sheet[s_i].row(row_id).default_format = format_sub_title
            sheet[s_i].row(row_id).push *["Evaluations pour l'année '%{year}'".trn(:year => year.to_i)]            
            evals.each do |e|
              row_id += 1
              sheet[s_i].row(row_id).default_format = format_row1 
              sheet[s_i].row(row_id).height = 80
              sheet[s_i].row(row_id).push *[Nokogiri::HTML(e.description).text.gsub(13.chr,'')] 
              sheet[s_i].merge_cells(row_id, 0, row_id, 7)
            end
          end

          c.get_eval_years.each do |tmp_year|
            if tmp_year != year.to_i
              evals = c.get_evals(tmp_year)
              if evals.size > 0
                row_id += 1
                row_id += 1
                sheet[s_i].row(row_id).default_format = format_sub_title
                sheet[s_i].row(row_id).push *["Evaluations pour l'année '%{year}'".trn(:year => tmp_year)]            
                evals.each do |e|
                  row_id += 1
                  sheet[s_i].row(row_id).default_format = format_row1 
                  sheet[s_i].row(row_id).height = 80
                  sheet[s_i].row(row_id).push *[Nokogiri::HTML(e.description).text.gsub(13.chr,'')]            
                  sheet[s_i].merge_cells(row_id, 0, row_id, 7)
                end
              end
            end
          end
        end
      end          
    end


    book.write file_name 
    return file_name 
    
  end

  def check_stock
    ok=true
    self.res_stocks.each do |s|
      if s.qty_real(s.quantity,s.quantity_added) < s.qty_need
        self.errors.add(:base,"Le stock réel '%{qty_real}' ne peut pas être inférieur aux besoins '%{qty_need}' pour la ressource '%{product}'.".trn(:qty_real => s.qty_real(s.quantity,s.quantity_added), :qty_need => s.qty_need, :product => s.res_product.name))
        ok=false
        break
      end
    end    
    return ok    
  end

end
