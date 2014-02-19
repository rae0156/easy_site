class AddSessionsTable < ActiveRecord::Migration
  def change
    create_table :es_sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.integer :es_user_id
      t.timestamps
    end

    add_index :es_sessions, :session_id
    add_index :es_sessions, :updated_at
  end
end
