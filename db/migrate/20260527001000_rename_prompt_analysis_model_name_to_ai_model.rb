class RenamePromptAnalysisModelNameToAiModel < ActiveRecord::Migration[8.0]
  def change
    rename_column :prompt_analyses, :model_name, :ai_model
  end
end
