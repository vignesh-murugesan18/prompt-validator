class PromptSession < ApplicationRecord
  has_many :prompt_analyses, dependent: :nullify
  has_many :prompt_experiments, dependent: :nullify
  has_one :notification_preference, dependent: :destroy

  validates :visitor_token, presence: true, uniqueness: true

  scope :recent_activity, -> { order(last_activity_at: :desc) }

  def touch_last_activity!
    update_column(:last_activity_at, Time.current)
  end

  def display_title
    title.presence || "Session · #{created_at.strftime('%b %-d, %Y')}"
  end

  def completed_analyses
    prompt_analyses.where(status: "completed").where.not(score: nil)
  end

  def link_email!(email_address)
    normalized = email_address.to_s.strip.downcase
    return if normalized.blank?

    update!(email: normalized)
    merge_sessions_by_email!(normalized)
  end

  private

  def merge_sessions_by_email!(normalized_email)
    PromptSession.where(email: normalized_email).where.not(id: id).find_each do |other|
      other.prompt_analyses.update_all(prompt_session_id: id)
      other.prompt_experiments.update_all(prompt_session_id: id)
      other.notification_preference&.destroy
      other.destroy
    end
  end
end
