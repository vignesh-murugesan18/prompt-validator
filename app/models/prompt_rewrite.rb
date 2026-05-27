class PromptRewrite < ApplicationRecord
  belongs_to :prompt_analysis

  STATUSES = %w[queued processing completed failed].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :strategy, presence: true
  validates :rewrites, presence: true, if: :completed?

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
end
