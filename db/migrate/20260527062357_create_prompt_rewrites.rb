class CreatePromptRewrites < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_rewrites do |t|
      t.references :prompt_analysis, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.text :error_message
      t.string :strategy, null: false, default: "default"
      t.jsonb :rewrites, null: false, default: []

      t.timestamps
    end

    add_index :prompt_rewrites, [:prompt_analysis_id, :strategy], unique: true
    add_index :prompt_rewrites, :status
  end
end
