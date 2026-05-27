class NotifyAnalysisCompleteJob < ApplicationJob
  queue_as :default

  def perform(prompt_analysis)
    session = prompt_analysis.prompt_session
    return unless session

    preference = session.notification_preference
    return unless preference&.notify_on_complete?
    return if preference.email.blank?
    return unless ENV["SMTP_ADDRESS"].present?

    PromptDigestMailer.analysis_complete_email(
      preference: preference,
      prompt_analysis: prompt_analysis
    ).deliver_now
  rescue StandardError => error
    Rails.logger.error("[NotifyAnalysisCompleteJob] #{error.message}")
  end
end
