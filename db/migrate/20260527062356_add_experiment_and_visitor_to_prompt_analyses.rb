class AddExperimentAndVisitorToPromptAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_reference :prompt_analyses, :prompt_experiment, null: true, foreign_key: true
    add_column :prompt_analyses, :visitor_token, :string

    add_index :prompt_analyses, :visitor_token
  end
end
