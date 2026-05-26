class ChangePromptAnalysesAiModelDefaultToGroq < ActiveRecord::Migration[8.0]
  def change
    change_column_default :prompt_analyses, :ai_model, from: "gemini-2.0-flash", to: "llama-3.1-8b-instant"
  end
end
