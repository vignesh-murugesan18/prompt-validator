class PromptAnalysesController < ApplicationController
  before_action :set_prompt_analysis, only: %i[show result]

  def create
    @prompt_analysis = PromptAnalysis.new(prompt_analysis_params)
    @prompt_analysis.status = "queued"
    @prompt_analysis.visitor_token = current_visitor_token
    @prompt_analysis.prompt_session = current_prompt_session

    if @prompt_analysis.save
      AnalyzePromptJob.perform_now(@prompt_analysis)
      redirect_to @prompt_analysis
    else
      load_home_collections
      render "home/index", status: :unprocessable_entity
    end
  end

  def show
  end

  def result
    render partial: "prompt_analyses/result", locals: { prompt_analysis: @prompt_analysis }
  end

  private

  def set_prompt_analysis
    @prompt_analysis = PromptAnalysis.find(params[:id])
  end

  def prompt_analysis_params
    params.require(:prompt_analysis).permit(:prompt_text, :ai_model, :web_search, :shared).tap do |permitted|
      permitted[:ai_model] = Ai::PromptAnalyzer.default_model if permitted[:ai_model].blank?
      permitted[:web_search] = ActiveModel::Type::Boolean.new.cast(permitted[:web_search])
      permitted[:shared] = ActiveModel::Type::Boolean.new.cast(permitted[:shared])
    end
  end

  def load_home_collections
    @examples = ExamplePrompt.limit(6)
    @your_recent_analyses = current_prompt_session.prompt_analyses.recent_first.limit(8)
    @recent_analyses = PromptAnalysis.shared_completed.recent_first.limit(10)
    @top_analyses = PromptAnalysis.shared_completed.within_last_day.top_scored.limit(6)
    @worst_analyses = PromptAnalysis.shared_completed.within_last_day.lowest_scored.limit(6)
  end
end
