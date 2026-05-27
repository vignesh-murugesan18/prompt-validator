class SlackDigestFormatter
  def initialize(digest:, session:)
    @digest = digest
    @session = session
  end

  def call
    lines = [
      "*#{digest.period_label} Prompt Coach digest*",
      "Analyses: #{digest.analysis_count} · Avg score: #{digest.overall_average}/10"
    ]

    if digest.score_change.present?
      arrow = digest.score_change >= 0 ? "↑" : "↓"
      lines << "Change: #{arrow} #{digest.score_change.abs} vs previous period"
    end

    if digest.weakest_principles.any?
      lines << ""
      lines << "*Focus areas:*"
      digest.weakest_principles.each do |row|
        lines << "• #{row[:name]} — #{row[:average]}/10"
      end
    end

    lines.join("\n")
  end

  private

  attr_reader :digest, :session
end
