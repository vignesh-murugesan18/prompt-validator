class SendPromptDigestJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |error|
    Rails.logger.error("[SendPromptDigestJob] #{error.class}: #{error.message}")
  end

  def perform(preference_id, frequency: "daily")
    preference = NotificationPreference.find_by(id: preference_id)
    return unless preference

    digest = PromptDigestBuilder.new(prompt_session: preference.prompt_session, period: frequency).call
    return if digest.nil?

    deliver_email(preference, digest)
    deliver_slack(preference, digest)

    preference.mark_digest_sent!
  end

  private

  def deliver_email(preference, digest)
    return if preference.email.blank?
    return unless ENV["SMTP_ADDRESS"].present?

    PromptDigestMailer.digest_email(preference: preference, digest: digest).deliver_now
  rescue StandardError => error
    Rails.logger.error("[SendPromptDigestJob] email failed: #{error.message}")
  end

  def deliver_slack(preference, digest)
    return if preference.slack_webhook_url.blank?

    text = SlackDigestFormatter.new(digest: digest, session: preference.prompt_session).call
    SlackWebhookClient.new(webhook_url: preference.slack_webhook_url).post_text(text)
  rescue SlackWebhookClient::Error => error
    Rails.logger.error("[SendPromptDigestJob] slack failed: #{error.message}")
  end
end
