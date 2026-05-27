class CreatePromptSessions < ActiveRecord::Migration[8.0]
  def change
    return if table_exists?(:prompt_sessions)

    create_table :prompt_sessions do |t|
      t.string :visitor_token, null: false
      t.string :email
      t.string :title
      t.datetime :last_activity_at, null: false

      t.timestamps
    end

    add_index :prompt_sessions, :visitor_token, unique: true
    add_index :prompt_sessions, :email
    add_index :prompt_sessions, :last_activity_at
  end
end
