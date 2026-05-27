class PromptDigestBuilder
  Result = Struct.new(
    :period_label,
    :analysis_count,
    :overall_average,
    :score_change,
    :weakest_principles,
    :recent_analyses,
    keyword_init: true
  )

  def initialize(prompt_session:, period: "daily")
    @prompt_session = prompt_session
    @period = period.to_s
  end

  def call
    range = period_range
    analyses = prompt_session.prompt_analyses
      .where(status: "completed")
      .where.not(score: nil)
      .where(updated_at: range)
      .order(updated_at: :desc)

    return nil if analyses.none?

    overall = (analyses.sum { |row| row.score.to_f } / analyses.size).round(1)
    previous = previous_period_analyses(range)
    score_change = previous.any? ? overall - (previous.sum { |r| r.score.to_f } / previous.size).round(1) : nil

    dashboard = PromptPrinciplesDashboard.new(prompt_analyses: analyses).call

    Result.new(
      period_label: period_label,
      analysis_count: analyses.size,
      overall_average: overall,
      score_change: score_change,
      weakest_principles: dashboard.weakest_principles,
      recent_analyses: analyses.limit(5)
    )
  end

  private

  attr_reader :prompt_session, :period

  def period_range
    case period
    when "weekly"
      7.days.ago..
    else
      1.day.ago..
    end
  end

  def previous_period_analyses(current_range)
    start = current_range.begin
    duration = period == "weekly" ? 7.days : 1.day
    previous_start = start - duration

    prompt_session.prompt_analyses
      .where(status: "completed")
      .where.not(score: nil)
      .where(updated_at: previous_start...start)
  end

  def period_label
    period == "weekly" ? "Weekly" : "Daily"
  end
end
