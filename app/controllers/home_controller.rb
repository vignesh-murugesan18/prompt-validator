class HomeController < ApplicationController
  def index
    @prompt_analysis = PromptAnalysis.new(shared: true, ai_model: Ai::PromptAnalyzer.default_model)
    @examples = ExamplePrompt.limit(6)
    @recent_analyses = PromptAnalysis.shared_completed.recent_first.limit(10)
    @top_analyses = PromptAnalysis.shared_completed.within_last_day.top_scored.limit(6)
    @worst_analyses = PromptAnalysis.shared_completed.within_last_day.lowest_scored.limit(6)
  end
end
