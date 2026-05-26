module ApplicationHelper
  PROMPT_PRINCIPLES = [
    "Let the AI Ask Questions",
    "Ask the AI to Think Out Loud",
    "Take It One Step at a Time",
    "Point to Code That Works",
    "Name Your Tools and Versions",
    "Explain Your Situation",
    "Be Clear About What You Want",
    "Show What You're Looking For",
    "Tell the AI Who to Be",
    "Say How You Want the Answer",
    "Organize Your Request Clearly",
    "Plan for Things Going Wrong",
    "Think About Weird Situations",
    "Don't Give Opposite Instructions"
  ].freeze

  def score_tone(score)
    numeric_score = score.to_f

    return "rose" if numeric_score < 4
    return "amber" if numeric_score < 7

    "emerald"
  end

  def score_badge_class(score)
    case score_tone(score)
    when "rose"
      "bg-rose-100 text-rose-600"
    when "amber"
      "bg-amber-100 text-amber-700"
    else
      "bg-emerald-100 text-emerald-700"
    end
  end

  def score_panel_class(score)
    case score_tone(score)
    when "rose"
      "bg-rose-100 text-rose-700"
    when "amber"
      "bg-amber-100 text-amber-800"
    else
      "bg-emerald-100 text-emerald-800"
    end
  end

  def score_segment_class(index, score)
    return "bg-slate-200" if index > score.to_f.round
    return "bg-rose-500" if index <= 3
    return "bg-amber-500" if index <= 6

    "bg-emerald-500"
  end

  def prompt_principle_rows(prompt_analysis)
    stored_rows = Array(prompt_analysis.analysis["principles"]).filter_map do |row|
      label = row["name"].presence || row["label"].presence
      next if label.blank?

      {
        label: label,
        score: clamp_score(row["score"]),
        feedback: row["feedback"].to_s.squish.presence
      }
    end

    return stored_rows if stored_rows.any?

    derived_principle_rows(prompt_analysis)
  end

  def prompt_principle_suggestion(row)
    return nil if row[:score].to_f >= 8

    case row[:label]
    when "Let the AI Ask Questions"
      "Add: If anything is unclear, ask me clarifying questions before answering."
    when "Ask the AI to Think Out Loud"
      "Ask for a short plan or reasoning before the AI writes code or gives the final answer."
    when "Take It One Step at a Time"
      "Break the request into numbered steps so the AI can complete the task sequentially."
    when "Point to Code That Works"
      "Reference an existing file, function, or example the AI should follow."
    when "Name Your Tools and Versions"
      "Name the framework, language, library, API, and version details when they matter."
    when "Explain Your Situation"
      "Add background about the project, current behavior, and why the change is needed."
    when "Be Clear About What You Want"
      "State the exact output or behavior you expect from the AI."
    when "Show What You're Looking For"
      "Give an example of the desired output or behavior."
    when "Tell the AI Who to Be"
      "Assign a role, such as senior Rails engineer, product designer, or code reviewer."
    when "Say How You Want the Answer"
      "Specify the format, style, and level of detail you want in the answer."
    when "Organize Your Request Clearly"
      "Use sections, bullets, or numbered tasks to make the request easier to scan."
    when "Plan for Things Going Wrong"
      "Mention failure cases, fallback behavior, validation, or tests."
    when "Think About Weird Situations"
      "Call out edge cases, unusual inputs, and exceptions the AI should consider."
    when "Don't Give Opposite Instructions"
      "Remove conflicting requirements and make priorities clear."
    end
  end

  private

  def derived_principle_rows(prompt_analysis)
    base_score = prompt_analysis.score.to_f
    offsets = [-4.0, -3.0, -2.0, -0.8, 0.2, 0.8, 1.0, 1.0, 0.8, 0.6, 0.7, 0.4, 0.4, 1.0]

    PROMPT_PRINCIPLES.zip(offsets).map do |label, offset|
      {
        label: label,
        score: clamp_score(base_score + offset),
        feedback: feedback_for_principle(label, prompt_analysis)
      }
    end
  end

  def feedback_for_principle(label, prompt_analysis)
    suggestions = Array(prompt_analysis.suggestions).join(" ")
    weaknesses = Array(prompt_analysis.weaknesses).join(" ")
    feedback = [suggestions, weaknesses].join(" ").squish

    return feedback.truncate(180) if feedback.present?

    "This principle is estimated from the overall score because this analysis was created before detailed principle scoring was available."
  end

  def clamp_score(value)
    [[value.to_f, 0].max, 10].min.round(1)
  end
end
