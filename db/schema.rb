# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131219170801) do

  create_table "es_articles", :force => true do |t|
    t.string   "name",           :limit => 200,  :null => false
    t.string   "description",    :limit => 4000, :null => false
    t.string   "content",        :limit => 4000, :null => false
    t.integer  "es_category_id"
    t.integer  "es_status_id"
    t.datetime "status_from"
    t.datetime "status_to"
  end

  create_table "es_categories", :force => true do |t|
    t.string  "name",          :limit => 30,                   :null => false
    t.integer "parent_id"
    t.string  "category_type", :limit => 200,                  :null => false
    t.string  "read_only",     :limit => 1,   :default => "Y", :null => false
  end

  create_table "es_content_details", :force => true do |t|
    t.integer "es_content_id"
    t.integer "sequence"
    t.string  "content",       :limit => 4000
  end

  create_table "es_contents", :force => true do |t|
    t.string "name", :limit => 200
  end

  create_table "es_fonctions", :force => true do |t|
    t.string  "code",           :limit => 200, :null => false
    t.string  "name",           :limit => 200, :null => false
    t.integer "es_category_id"
  end

  create_table "es_langages", :force => true do |t|
    t.string  "code",           :limit => 200, :null => false
    t.string  "valeur",         :limit => 200, :null => false
    t.integer "es_category_id"
  end

  create_table "es_media_files", :force => true do |t|
    t.string  "name",           :limit => 30,   :null => false
    t.string  "title",          :limit => 50
    t.string  "description",    :limit => 4000
    t.string  "path",           :limit => 500
    t.string  "media_type",     :limit => 20
    t.string  "reference",      :limit => 200
    t.integer "sequence"
    t.integer "parent_id"
    t.integer "es_category_id"
    t.integer "height"
    t.integer "width"
  end

  create_table "es_menus", :force => true do |t|
    t.string  "name",           :limit => 200,  :null => false
    t.string  "description",    :limit => 4000, :null => false
    t.string  "link_type",      :limit => 20,   :null => false
    t.string  "link_params",    :limit => 4000
    t.integer "es_category_id"
    t.integer "parent_id"
    t.integer "sequence"
  end

  create_table "es_parts", :force => true do |t|
    t.string  "name",           :limit => 200,  :null => false
    t.string  "description",    :limit => 4000
    t.integer "es_template_id",                 :null => false
    t.integer "es_content_id"
  end

  create_table "es_roles", :force => true do |t|
    t.string  "description",    :limit => 20
    t.integer "es_category_id"
  end

  create_table "es_roles_es_users", :id => false, :force => true do |t|
    t.integer "es_user_id", :null => false
    t.integer "es_role_id", :null => false
  end

  create_table "es_setups", :force => true do |t|
    t.string  "name",            :limit => 30,   :null => false
    t.string  "value",           :limit => 1000
    t.string  "type_data",       :limit => 20
    t.string  "read_only",       :limit => 1
    t.string  "path",            :limit => 500
    t.integer "nbr_element"
    t.string  "possible_values", :limit => 500
    t.integer "parent_id"
    t.integer "es_category_id"
  end

  create_table "es_statuses", :force => true do |t|
    t.string  "name",           :limit => 200, :null => false
    t.integer "es_category_id",                :null => false
  end

  create_table "es_templates", :force => true do |t|
    t.string  "name",           :limit => 200,  :null => false
    t.string  "description",    :limit => 4000, :null => false
    t.integer "es_category_id"
  end

  create_table "es_users", :force => true do |t|
    t.string   "name",                   :limit => 50
    t.string   "firstname",              :limit => 50
    t.string   "mail",                   :limit => 50
    t.string   "active",                 :limit => 20,  :default => "Y"
    t.string   "password_hash",          :limit => 200
    t.string   "tempo_password",         :limit => 20
    t.string   "address1",               :limit => 200
    t.string   "address2",               :limit => 200
    t.string   "zip",                    :limit => 10
    t.string   "city",                   :limit => 200
    t.string   "country",                :limit => 200
    t.string   "tel",                    :limit => 50
    t.string   "gsm",                    :limit => 50
    t.integer  "es_category_id"
    t.string   "email",                                 :default => "",  :null => false
    t.string   "encrypted_password",                    :default => "",  :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0,   :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "es_users", ["email"], :name => "index_es_users_on_email", :unique => true
  add_index "es_users", ["reset_password_token"], :name => "index_es_users_on_reset_password_token", :unique => true

end
