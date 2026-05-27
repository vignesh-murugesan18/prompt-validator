class PromptPrinciplesDashboard
  Result = Struct.new(
    :overall_average,
    :analysis_count,
    :principles,
    :weakest_principles,
    keyword_init: true
  )

  def initialize(prompt_analyses:)
    @prompt_analyses = Array(prompt_analyses)
  end

  def call
    completed = prompt_analyses.select(&:completed?).select { |row| row.score.present? }
    return Result.new(overall_average: 0.0, analysis_count: 0, principles: [], weakest_principles: []) if completed.empty?

    principle_scores = Hash.new { |h, k| h[k] = [] }

    completed.each do |analysis|
      Array(analysis.analysis["principles"]).each do |row|
        name = row["name"].to_s.presence || row["label"].to_s
        score = row["score"]
        next if name.blank?
        next if score.blank?

        principle_scores[name] << score.to_f
      end
    end

    principle_rows = ApplicationHelper::PROMPT_PRINCIPLES.map do |name|
      scores = principle_scores[name]
      avg = scores.present? ? (scores.sum / scores.size).round(1) : 0.0

      {
        name: name,
        average: avg,
        samples: scores.size
      }
    end

    weakest = principle_rows.sort_by { |row| [row[:average], -row[:samples]] }.first(3)

    overall = (completed.sum { |a| a.score.to_f } / completed.size).round(1)

    Result.new(
      overall_average: overall,
      analysis_count: completed.size,
      principles: principle_rows,
      weakest_principles: weakest
    )
  end

  private

  attr_reader :prompt_analyses
end

