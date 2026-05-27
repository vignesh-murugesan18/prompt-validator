class PromptExperiment < ApplicationRecord
  STATUSES = %w[queued processing completed failed].freeze

  has_many :prompt_analyses, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }
  validates :ai_model, presence: true

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def pending?
    %w[queued processing].include?(status)
  end

  def refresh_status!
    if prompt_analyses.any?(&:pending?)
      update!(status: "processing") if status != "processing"
      return
    end

    if prompt_analyses.any?(&:failed?)
      update!(status: "failed")
    else
      update!(status: "completed")
    end
  end
end

