class AnalyzePromptJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |error|
    prompt_analysis = arguments.first
    prompt_analysis&.update(status: "failed", error_message: error.message)
  end

  def perform(prompt_analysis)
    prompt_analysis.update!(status: "processing", error_message: nil)

    result = Ai::PromptAnalyzer.new(prompt_analysis: prompt_analysis).call

    prompt_analysis.update!(
      status: "completed",
      score: result.fetch(:score),
      summary: result.fetch(:summary),
      strengths: result.fetch(:strengths),
      weaknesses: result.fetch(:weaknesses),
      suggestions: result.fetch(:suggestions),
      analysis: result.fetch(:analysis)
    )

    prompt_analysis.prompt_session&.touch_last_activity!
    NotifyAnalysisCompleteJob.perform_later(prompt_analysis)
  end
end
