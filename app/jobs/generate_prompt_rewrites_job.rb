class GeneratePromptRewritesJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |error|
    prompt_analysis = arguments.first
    strategy = arguments.second.to_s.presence || "default"

    if prompt_analysis.present?
      rewrite = PromptRewrite.find_or_initialize_by(prompt_analysis: prompt_analysis, strategy: strategy)
      rewrite.update(status: "failed", error_message: error.message, rewrites: [])
    end
  end

  def perform(prompt_analysis, strategy: "default")
    rewrite = PromptRewrite.find_or_initialize_by(prompt_analysis: prompt_analysis, strategy: strategy)
    rewrite.update!(status: "processing", error_message: nil)

    rows = Ai::PromptRewriter.new(prompt_analysis: prompt_analysis, strategy: strategy).call

    rewrite.update!(status: "completed", rewrites: rows)
  end
end

