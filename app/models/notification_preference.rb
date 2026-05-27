class NotificationPreference < ApplicationRecord
  DIGEST_FREQUENCIES = %w[none daily weekly].freeze

  belongs_to :prompt_session

  validates :digest_frequency, inclusion: { in: DIGEST_FREQUENCIES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :email_required_for_digest

  scope :digest_enabled, ->(frequency) { where(digest_frequency: frequency) }
  scope :with_notifications, -> {
    where(notify_on_complete: true)
      .or(where.not(digest_frequency: "none"))
      .or(where.not(slack_webhook_url: [nil, ""]))
  }

  def digest_enabled?
    digest_frequency != "none"
  end

  def due_for_digest?(frequency = digest_frequency)
    return false unless digest_frequency == frequency
    return false if email.blank? && slack_webhook_url.blank?

    window = frequency == "weekly" ? 6.days : 20.hours
    last_digest_sent_at.blank? || last_digest_sent_at < window.ago
  end

  def mark_digest_sent!
    update!(last_digest_sent_at: Time.current)
  end

  private

  def email_required_for_digest
    return if digest_frequency == "none"
    return if email.present?

    errors.add(:email, "is required for email digests")
  end
end
