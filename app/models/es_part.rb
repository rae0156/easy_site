# encoding: UTF-8

class EsPart < ActiveRecord::Base

  belongs_to :es_template
  belongs_to :es_content

  attr_accessible :name, :description, :es_template_id, :es_content_id, :created_at, :active, :nombre, :valeur
end