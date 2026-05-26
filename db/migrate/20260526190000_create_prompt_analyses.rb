class CreatePromptAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_analyses do |t|
      t.text :prompt_text, null: false
      t.decimal :score, precision: 3, scale: 1
      t.text :summary
      t.jsonb :strengths, null: false, default: []
      t.jsonb :weaknesses, null: false, default: []
      t.jsonb :suggestions, null: false, default: []
      t.jsonb :analysis, null: false, default: {}
      t.string :model_name, null: false, default: "gemini-2.0-flash"
      t.boolean :web_search, null: false, default: false
      t.boolean :shared, null: false, default: true
      t.string :status, null: false, default: "queued"
      t.text :error_message

      t.timestamps
    end

    add_index :prompt_analyses, [:shared, :status, :created_at]
    add_index :prompt_analyses, [:shared, :status, :score]
    add_index :prompt_analyses, :status
  end
end
