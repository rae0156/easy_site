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

ActiveRecord::Schema.define(:version => 20160203180133) do

  create_table "action_codes", :force => true do |t|
    t.string  "code",        :limit => 50,  :null => false
    t.string  "description", :limit => 200
    t.integer "es_site_id"
  end

  create_table "action_screens", :force => true do |t|
    t.integer "action_user_id", :null => false
    t.integer "x",              :null => false
    t.integer "y",              :null => false
    t.integer "user_id"
    t.integer "es_site_id"
  end

  create_table "action_type_params", :force => true do |t|
    t.integer "action_type_id",                :null => false
    t.string  "name",           :limit => 50,  :null => false
    t.string  "description",    :limit => 200
    t.string  "type_param",     :limit => 50,  :null => false
    t.string  "value_list",     :limit => 200
    t.integer "es_site_id"
  end

  create_table "action_types", :force => true do |t|
    t.string  "name",          :limit => 50,  :null => false
    t.string  "description",   :limit => 200
    t.string  "caller_type",   :limit => 20
    t.string  "caller_name",   :limit => 50
    t.string  "caller_action", :limit => 50
    t.integer "es_site_id"
  end

  create_table "action_user_params", :force => true do |t|
    t.integer "action_user_id",                      :null => false
    t.integer "action_type_param_id",                :null => false
    t.string  "value",                :limit => 200, :null => false
    t.integer "es_site_id"
  end

  create_table "action_users", :force => true do |t|
    t.string  "name",            :limit => 50,                   :null => false
    t.integer "action_type_id",                                  :null => false
    t.string  "description",     :limit => 200
    t.string  "target_other",    :limit => 1,   :default => "Y"
    t.string  "image_name",      :limit => 200
    t.string  "image_with_text", :limit => 1,   :default => "Y"
    t.integer "user_id"
    t.integer "es_site_id"
  end

  create_table "action_users_postit_tasks", :id => false, :force => true do |t|
    t.integer "action_user_id", :default => 0, :null => false
    t.integer "postit_task_id", :default => 0, :null => false
  end

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type",       :limit => 400
    t.integer  "user_id"
    t.string   "action",               :limit => 400
    t.text     "changes_audit"
    t.integer  "version",                             :default => 0
    t.datetime "created_at"
    t.string   "username",             :limit => 400
    t.string   "user_type",            :limit => 400
    t.string   "auditable_label",      :limit => 200
    t.string   "process_label",        :limit => 200
    t.string   "auditable_type_label", :limit => 200
  end

  create_table "blogit_comments", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "email",      :null => false
    t.string   "website"
    t.text     "body",       :null => false
    t.integer  "post_id",    :null => false
    t.string   "state"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "blogit_comments", ["post_id"], :name => "index_blogit_comments_on_post_id"

  create_table "blogit_posts", :force => true do |t|
    t.string   "title",                               :null => false
    t.text     "body",                                :null => false
    t.string   "state",          :default => "draft", :null => false
    t.integer  "comments_count", :default => 0,       :null => false
    t.integer  "blogger_id"
    t.string   "blogger_type"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.text     "description"
  end

  add_index "blogit_posts", ["blogger_type", "blogger_id"], :name => "index_blogit_posts_on_blogger_type_and_blogger_id"

  create_table "dir_accesses", :force => true do |t|
    t.integer  "dir_manager_id"
    t.string   "name",           :limit => 50,                   :null => false
    t.string   "description",    :limit => 200
    t.string   "all_role",       :limit => 1,   :default => "N"
    t.string   "dir_view",       :limit => 1,   :default => "N"
    t.string   "file_view",      :limit => 1,   :default => "N"
    t.string   "file_update",    :limit => 1,   :default => "N"
    t.string   "dir_del",        :limit => 1,   :default => "N"
    t.string   "file_del",       :limit => 1,   :default => "N"
    t.string   "dir_create",     :limit => 1,   :default => "N"
    t.string   "file_create",    :limit => 1,   :default => "N"
    t.string   "dir_rename",     :limit => 1,   :default => "N"
    t.string   "file_rename",    :limit => 1,   :default => "N"
    t.string   "file_download",  :limit => 1,   :default => "N"
    t.string   "file_upload",    :limit => 1,   :default => "N"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "dir_accesses_es_roles", :id => false, :force => true do |t|
    t.integer "dir_access_id", :default => 0, :null => false
    t.integer "es_role_id",    :default => 0, :null => false
  end

  create_table "dir_bases", :force => true do |t|
    t.string   "name",        :limit => 50,  :null => false
    t.string   "description", :limit => 200
    t.string   "local_path",  :limit => 200
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "dir_managers", :force => true do |t|
    t.string   "name",            :limit => 50,                   :null => false
    t.string   "description",     :limit => 200
    t.integer  "dir_base_id"
    t.string   "real_dir",        :limit => 200
    t.string   "file_ext",        :limit => 50
    t.string   "sub_dir_by_user", :limit => 1,   :default => "N"
    t.integer  "limit_size"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "dyn_export_details", :force => true do |t|
    t.integer "dyn_export_id",                                  :null => false
    t.string  "clause",        :limit => 20
    t.integer "sequence"
    t.string  "name",          :limit => 200
    t.string  "operator",      :limit => 200
    t.string  "argument",      :limit => 4000
    t.string  "params",        :limit => 400
    t.string  "active",        :limit => 1,    :default => "Y"
    t.integer "es_site_id"
  end

  create_table "dyn_exports", :force => true do |t|
    t.string   "code",        :limit => 50
    t.string   "name",        :limit => 400
    t.string   "description", :limit => 2000
    t.string   "active",      :limit => 1,    :default => "Y"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "dynamic_model_field_setups", :force => true do |t|
    t.string  "field_name",             :limit => 30, :null => false
    t.integer "dynamic_model_setup_id"
  end

  create_table "dynamic_model_setups", :force => true do |t|
    t.string "model_name", :limit => 30,                  :null => false
    t.string "label",      :limit => 50
    t.string "read_only",  :limit => 1,  :default => "Y", :null => false
  end

  create_table "es_abilities", :force => true do |t|
    t.string  "model",                 :limit => 4000
    t.string  "action",                :limit => 4000
    t.string  "description",           :limit => 200
    t.integer "es_site_id"
    t.string  "read_only",             :limit => 1,    :default => "N"
    t.string  "include_not_connected", :limit => 1,    :default => "N"
  end

  create_table "es_abilities_es_roles", :id => false, :force => true do |t|
    t.integer "es_ability_id", :default => 0, :null => false
    t.integer "es_role_id",    :default => 0, :null => false
  end

  create_table "es_attribute_types", :force => true do |t|
    t.string  "attribute_type", :limit => 50,                    :null => false
    t.string  "name",           :limit => 50,                    :null => false
    t.string  "type_data",      :limit => 20,                    :null => false
    t.string  "type_param",     :limit => 2000
    t.string  "category",       :limit => 200
    t.string  "mandatory",      :limit => 1,    :default => "N", :null => false
    t.string  "default_value",  :limit => 200
    t.string  "comments",       :limit => 200
    t.integer "length"
    t.integer "decimal_nbr"
    t.string  "choices",        :limit => 200
    t.integer "order_seq"
    t.string  "read_only",      :limit => 1,    :default => "N"
  end

  create_table "es_attributes", :force => true do |t|
    t.integer  "attributable_id",                        :null => false
    t.string   "attributable_type",     :limit => 50,    :null => false
    t.integer  "dyn_attribute_type_id",                  :null => false
    t.string   "value",                 :limit => 10000
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
  end

  create_table "es_categories", :force => true do |t|
    t.string  "name",          :limit => 30,                   :null => false
    t.integer "parent_id"
    t.string  "category_type", :limit => 200,                  :null => false
    t.string  "read_only",     :limit => 1,   :default => "Y", :null => false
    t.integer "es_site_id"
  end

  create_table "es_content_detail_elements", :force => true do |t|
    t.string   "name",                 :limit => 200,  :null => false
    t.string   "description",          :limit => 4000
    t.string   "element_type",         :limit => 50,   :null => false
    t.integer  "es_content_detail_id",                 :null => false
    t.integer  "parent_id"
    t.integer  "num"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "es_site_id"
  end

  create_table "es_content_detail_params", :force => true do |t|
    t.integer "es_content_detail_id"
    t.integer "sequence"
    t.string  "setup_name",           :limit => 200
    t.string  "value",                :limit => 200
    t.string  "type_setup",           :limit => 50
    t.string  "updatable",            :limit => 1,   :default => "N"
    t.string  "description",          :limit => 200
    t.string  "value_list",           :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_content_details", :force => true do |t|
    t.integer "es_content_id"
    t.decimal "sequence",                           :precision => 11, :scale => 2
    t.string  "content",            :limit => 4000
    t.string  "editable",           :limit => 1,                                   :default => "N"
    t.integer "es_site_id"
    t.string  "content_type",       :limit => 20,                                  :default => "system"
    t.string  "module_action_name", :limit => 200
  end

  create_table "es_contents", :force => true do |t|
    t.string  "name",       :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_dyn_pages", :force => true do |t|
    t.string  "name",           :limit => 200,  :null => false
    t.string  "description",    :limit => 4000
    t.string  "page_type",      :limit => 200,  :null => false
    t.integer "es_site_id"
    t.integer "es_template_id"
  end

  create_table "es_languages", :force => true do |t|
    t.string  "code",       :limit => 400
    t.string  "text_fr",    :limit => 400
    t.string  "text_en",    :limit => 400
    t.string  "text_de",    :limit => 400
    t.string  "translated", :limit => 1,   :default => "N"
    t.integer "es_site_id"
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
    t.integer "es_site_id"
    t.string  "model_type",     :limit => 50
  end

  create_table "es_menus", :force => true do |t|
    t.string  "name",           :limit => 200,                   :null => false
    t.string  "description",    :limit => 4000
    t.string  "link_type",      :limit => 20,                    :null => false
    t.string  "controller",     :limit => 200
    t.string  "action",         :limit => 200
    t.string  "link_params",    :limit => 4000
    t.integer "es_category_id"
    t.integer "es_site_id"
    t.integer "parent_id"
    t.integer "sequence"
    t.integer "creator_id"
    t.integer "updater_id"
    t.string  "read_only",      :limit => 1,    :default => "N"
    t.string  "all_roles",      :limit => 1,    :default => "N"
    t.string  "model_type",     :limit => 50
  end

  add_index "es_menus", ["es_site_id", "parent_id", "sequence"], :name => "menu_index"

  create_table "es_menus_es_roles", :id => false, :force => true do |t|
    t.integer "es_menu_id", :default => 0, :null => false
    t.integer "es_role_id", :default => 0, :null => false
  end

  create_table "es_modules", :force => true do |t|
    t.string "path_setup",  :limit => 200
    t.string "setup_name",  :limit => 200
    t.string "value",       :limit => 200
    t.string "type_setup",  :limit => 50
    t.string "module_name", :limit => 40
    t.string "updatable",   :limit => 1,   :default => "N"
    t.string "description", :limit => 200
    t.string "value_list",  :limit => 200
  end

  create_table "es_pages", :force => true do |t|
    t.string  "action",          :limit => 200
    t.string  "controller",      :limit => 200
    t.integer "es_template_id"
    t.integer "es_theme_id"
    t.string  "flag_admin",      :limit => 1,   :default => "Y"
    t.string  "flag_connection", :limit => 1,   :default => "Y"
    t.string  "signed",          :limit => 1,   :default => "N"
    t.string  "read_only",       :limit => 1,   :default => "N"
    t.integer "es_site_id"
  end

  create_table "es_parts", :force => true do |t|
    t.string   "name",               :limit => 200,  :null => false
    t.string   "description",        :limit => 4000
    t.integer  "es_template_id",                     :null => false
    t.integer  "es_content_id"
    t.integer  "es_template_col_id"
    t.integer  "num"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "es_site_id"
  end

  create_table "es_roles", :force => true do |t|
    t.string  "name",           :limit => 40
    t.string  "description",    :limit => 200
    t.integer "es_category_id"
    t.string  "read_only",      :limit => 1,   :default => "N"
    t.integer "es_site_id"
    t.string  "role_site",      :limit => 1,   :default => "N"
  end

  create_table "es_roles_es_users", :id => false, :force => true do |t|
    t.integer "es_user_id", :null => false
    t.integer "es_role_id", :null => false
  end

  create_table "es_roles_es_workflows", :id => false, :force => true do |t|
    t.integer "es_role_id",      :default => 0, :null => false
    t.integer "dyn_workflow_id", :default => 0, :null => false
  end

  create_table "es_sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.integer  "es_user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "es_sessions", ["session_id"], :name => "index_es_sessions_on_session_id"
  add_index "es_sessions", ["updated_at"], :name => "index_es_sessions_on_updated_at"

  create_table "es_setups", :force => true do |t|
    t.string  "name",            :limit => 30,   :null => false
    t.string  "value",           :limit => 1000
    t.string  "type_data",       :limit => 20
    t.string  "read_only",       :limit => 1
    t.string  "path",            :limit => 500
    t.string  "possible_values", :limit => 500
    t.integer "parent_id"
    t.integer "es_category_id"
    t.integer "es_site_id"
  end

  create_table "es_sites", :force => true do |t|
    t.string "code",           :limit => 20
    t.string "description",    :limit => 400
    t.string "active",         :limit => 1,   :default => "Y"
    t.string "set_as_default", :limit => 1,   :default => "N"
    t.string "protected",      :limit => 1,   :default => "N"
  end

  create_table "es_template_cols", :force => true do |t|
    t.integer "num",                                :null => false
    t.integer "es_template_line_id"
    t.integer "width"
    t.string  "description",         :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_template_lines", :force => true do |t|
    t.decimal "num",              :precision => 11, :scale => 2,                :null => false
    t.integer "es_template_id",                                  :default => 0
    t.integer "es_site_id"
    t.integer "es_col_parent_id",                                :default => 0
  end

  create_table "es_templates", :force => true do |t|
    t.string  "name",           :limit => 200,                          :null => false
    t.string  "description",    :limit => 4000,                         :null => false
    t.integer "es_category_id"
    t.integer "es_site_id"
    t.string  "validated",      :limit => 1,    :default => "N"
    t.string  "template_type",  :limit => 15,   :default => "TEMPLATE"
  end

  create_table "es_tests", :force => true do |t|
    t.string  "code",        :limit => 20
    t.string  "description", :limit => 400
    t.string  "active",      :limit => 1,   :default => "Y"
    t.string  "other_field", :limit => 1,   :default => "N"
    t.integer "sequence"
    t.integer "parent_id"
    t.integer "test_i"
    t.integer "es_page_id"
    t.string  "test_list",   :limit => 20
  end

  create_table "es_themes", :force => true do |t|
    t.string  "code",       :limit => 40
    t.string  "file",       :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_users", :force => true do |t|
    t.string  "name",           :limit => 50
    t.string  "firstname",      :limit => 50
    t.string  "mail",           :limit => 60
    t.string  "active",         :limit => 20,  :default => "Y"
    t.string  "password_hash",  :limit => 200
    t.string  "tempo_password", :limit => 20
    t.string  "address1",       :limit => 200
    t.string  "address2",       :limit => 200
    t.string  "zip",            :limit => 10
    t.string  "city",           :limit => 200
    t.string  "country",        :limit => 200
    t.string  "tel",            :limit => 50
    t.string  "gsm",            :limit => 50
    t.integer "es_site_id"
    t.string  "pseudo",         :limit => 200
    t.string  "newmail",        :limit => 60
    t.string  "activemail",     :limit => 200
  end

  add_index "es_users", ["mail", "es_site_id"], :name => "index_es_users_on_mail_and_es_site_id", :unique => true

  create_table "es_wizard_details", :force => true do |t|
    t.integer "es_wizard_id"
    t.decimal "sequence",                     :precision => 11, :scale => 2
    t.string  "name",         :limit => 200,                                 :null => false
    t.string  "description",  :limit => 4000
    t.string  "action",       :limit => 200
    t.string  "render_name",  :limit => 200
    t.string  "params",       :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_wizards", :force => true do |t|
    t.string  "name",        :limit => 200,  :null => false
    t.string  "description", :limit => 4000
    t.string  "wizard_type", :limit => 20,   :null => false
    t.integer "es_site_id"
  end

  create_table "es_workflow_statuses", :force => true do |t|
    t.string  "status_name", :limit => 50
    t.string  "label",       :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_workflow_types", :force => true do |t|
    t.string  "code",       :limit => 50
    t.string  "label",      :limit => 200
    t.integer "es_site_id"
  end

  create_table "es_workflows", :force => true do |t|
    t.integer "start_status_id"
    t.integer "end_status_id"
    t.string  "check_user",           :limit => 1,   :default => "N"
    t.integer "dyn_workflow_type_id"
    t.string  "comments",             :limit => 200
    t.integer "es_site_id"
  end

  create_table "postit_lists", :force => true do |t|
    t.string   "name",            :limit => 200,                   :null => false
    t.string   "description",     :limit => 4000
    t.integer  "postit_phase_id"
    t.string   "sequential",      :limit => 1,    :default => "Y"
    t.string   "checkable",       :limit => 1,    :default => "Y"
    t.string   "templatable",     :limit => 1,    :default => "N"
    t.string   "completed",       :limit => 1,    :default => "N"
    t.integer  "owner_id"
    t.datetime "close_date"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "postit_phases", :force => true do |t|
    t.string   "name",                   :limit => 200,                   :null => false
    t.string   "description",            :limit => 4000
    t.integer  "postit_process_id"
    t.string   "templatable",            :limit => 1,    :default => "N"
    t.integer  "dyn_workflow_status_id"
    t.integer  "owner_id"
    t.datetime "close_date"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "postit_processes", :force => true do |t|
    t.string   "name",                   :limit => 200,                   :null => false
    t.string   "description",            :limit => 4000
    t.string   "templatable",            :limit => 1,    :default => "N"
    t.string   "completed",              :limit => 1,    :default => "N"
    t.integer  "dyn_workflow_status_id"
    t.integer  "dyn_workflow_user_id"
    t.integer  "dyn_workflow_type_id"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.datetime "close_date"
    t.integer  "es_site_id"
  end

  create_table "postit_tasks", :force => true do |t|
    t.string   "name",           :limit => 200,                                                  :null => false
    t.string   "description",    :limit => 4000
    t.integer  "postit_list_id"
    t.decimal  "sequence",                       :precision => 11, :scale => 2
    t.string   "checked",        :limit => 1,                                   :default => "N"
    t.string   "templatable",    :limit => 1,                                   :default => "N"
    t.string   "optional",       :limit => 1,                                   :default => "N"
    t.integer  "owner_id"
    t.datetime "close_date"
    t.datetime "created_at"
    t.integer  "created_by"
    t.datetime "updated_at"
    t.integer  "updated_by"
    t.integer  "es_site_id"
  end

  create_table "v_audit_group", :id => false, :force => true do |t|
    t.string  "max_type",    :limit => 400
    t.integer "max_id"
    t.integer "max_version"
  end

  create_table "v_audit_versions", :id => false, :force => true do |t|
    t.integer  "id",                                  :default => 0, :null => false
    t.integer  "auditable_id"
    t.string   "auditable_type",       :limit => 400
    t.integer  "user_id"
    t.string   "user_type",            :limit => 400
    t.string   "username",             :limit => 400
    t.string   "action",               :limit => 400
    t.text     "changes_audit"
    t.integer  "version",                             :default => 0
    t.datetime "created_at"
    t.string   "auditable_label",      :limit => 200
    t.string   "process_label",        :limit => 200
    t.string   "auditable_type_label", :limit => 200
  end

end
