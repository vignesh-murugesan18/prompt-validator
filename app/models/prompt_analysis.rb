class PromptAnalysis < ApplicationRecord
  STATUSES = %w[queued processing completed failed].freeze
  MIN_PROMPT_LENGTH = 40

  validates :prompt_text, presence: true, length: { minimum: MIN_PROMPT_LENGTH, maximum: 20_000 }
  validates :status, inclusion: { in: STATUSES }
  validates :ai_model, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true

  scope :shared_completed, -> { where(shared: true, status: "completed").where.not(score: nil) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :within_last_day, -> { where(created_at: 24.hours.ago..) }
  scope :top_scored, -> { order(score: :desc, created_at: :desc) }
  scope :lowest_scored, -> { order(score: :asc, created_at: :desc) }

  def queued?
    status == "queued"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def pending?
    queued? || processing?
  end

  def prompt_preview(length = 220)
    prompt_text.to_s.squish.truncate(length)
  end
end
