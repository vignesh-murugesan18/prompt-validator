class PromptRewritesController < ApplicationController
  before_action :set_prompt_analysis

  def create
    @rewrite = PromptRewrite.find_or_initialize_by(prompt_analysis: @prompt_analysis, strategy: strategy_param)
    @rewrite.update(status: "queued", error_message: nil, rewrites: [])

    GeneratePromptRewritesJob.perform_now(@prompt_analysis, strategy: strategy_param)

    redirect_to prompt_analysis_prompt_rewrite_path(@prompt_analysis, strategy: strategy_param)
  end

  def show
    @rewrite = PromptRewrite.find_or_initialize_by(prompt_analysis: @prompt_analysis, strategy: strategy_param)
  end

  private

  def set_prompt_analysis
    @prompt_analysis = PromptAnalysis.find(params[:prompt_analysis_id])
  end

  def strategy_param
    params[:strategy].to_s.presence || "default"
  end
end

