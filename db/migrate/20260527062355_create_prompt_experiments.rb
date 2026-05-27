class CreatePromptExperiments < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_experiments do |t|
      t.string :title
      t.text :goal
      t.string :ai_model, null: false, default: "llama-3.1-8b-instant"
      t.boolean :web_search, null: false, default: false
      t.string :status, null: false, default: "queued"
      t.text :error_message

      t.timestamps
    end

    add_index :prompt_experiments, :status
    add_index :prompt_experiments, :created_at
  end
end
