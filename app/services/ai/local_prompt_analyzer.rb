module Ai
  class LocalPromptAnalyzer
    PRINCIPLE_RULES = {
      "Let the AI Ask Questions" => {
        pattern: /\b(ask (me|clarifying|questions?)|clarifying questions?|before (you )?(start|answer|code)|if .*missing.*ask)\b/i,
        good: "The request explicitly invites the AI to ask clarifying questions before answering.",
        improve: "No additional guidance or prompting strategy was provided to encourage the AI to ask clarifying questions before answering."
      },
      "Ask the AI to Think Out Loud" => {
        pattern: /\b(reason step.by.step|think (through|out loud)|explain (your )?(reasoning|approach|why)|tradeoffs?|plan before|before .*code)\b/i,
        good: "The request explicitly asks the AI to reason through the approach before producing the final answer.",
        improve: "The request did not explicitly instruct the AI to reason step-by-step before generating code or solutions."
      },
      "Take It One Step at a Time" => {
        pattern: /\b(step \d+|step-by-step|one step at a time|first.*then|sequential|incremental)\b/i,
        good: "The request breaks the work into sequential steps.",
        improve: "Some structure exists, but the request could better break the task into smaller sequential steps."
      },
      "Point to Code That Works" => {
        pattern: /(@[\w\/.-]+|\b(existing|follow the pattern|like this|example|sample|working|reference|expected output)\b)/i,
        good: "The request points to references, examples, or existing patterns the AI can follow.",
        improve: "Point to working code, examples, or expected outputs so the AI has a concrete reference."
      },
      "Name Your Tools and Versions" => {
        pattern: /\b(rails|ruby|react|next\.?js|typescript|tailwind|postgres|sql|api|model|controller|version|v\d+|\d+\.\d+)\b/i,
        good: "The request names relevant tools, frameworks, or environment details.",
        improve: "Name the tools, frameworks, versions, or environment details needed for an accurate answer."
      },
      "Explain Your Situation" => {
        pattern: /\b(project|app|currently|existing|using|rails|react|next|controller|model|database)\b/i,
        good: "The overall problem and background are explained with useful context.",
        improve: "The request needs more background about the current situation, codebase, and problem being solved."
      },
      "Be Clear About What You Want" => {
        pattern: /\b(add|build|create|fix|update|review|explain|implement|design|refactor|need|want)\b/i,
        good: "The request clearly defines the desired outcome and expectations.",
        improve: "The desired outcome is not clear enough; state exactly what should be changed or produced."
      },
      "Show What You're Looking For" => {
        pattern: /\b(example|like this|similar to|screenshot|attached|sample|expected)\b/i,
        good: "Examples and references were provided effectively to demonstrate expectations.",
        improve: "No concrete examples, screenshots, or expected outputs were provided to demonstrate expectations."
      },
      "Tell the AI Who to Be" => {
        pattern: /\b(act as|you are|senior|expert|role|coach|engineer|designer)\b/i,
        good: "The request clearly defines the expected role or persona for the AI.",
        improve: "The request does not define what role or expertise the AI should use."
      },
      "Say How You Want the Answer" => {
        pattern: /\b(format|bullet|list|table|json|concise|return|respond|answer style|include)\b/i,
        good: "The desired response format and style are clearly specified.",
        improve: "The request does not clearly specify the desired answer format, style, or level of detail."
      },
      "Organize Your Request Clearly" => {
        pattern: /\n|:|- |\d+\./,
        good: "The request is well-structured and easy to follow.",
        improve: "The request could be organized more clearly with sections, bullets, or numbered steps."
      },
      "Plan for Things Going Wrong" => {
        pattern: /\b(error|failure|fallback|invalid|empty|timeout|wrong|test|verify|rollback|guard)\b/i,
        good: "Edge cases, fallback handling, and failure conditions are considered.",
        improve: "The request does not include enough guidance for errors, fallbacks, validation, or failure conditions."
      },
      "Think About Weird Situations" => {
        pattern: /\b(edge|weird|corner|unexpected|race|nil|null|blank|large|slow|never|duplicate|exception)\b/i,
        good: "Unusual scenarios and exceptions are addressed properly.",
        improve: "The request does not call out unusual scenarios, exceptions, or edge cases."
      },
      "Don't Give Opposite Instructions" => {
        pattern: /\b(ignore|but|however|except|do not|don't|without|only|must)\b/i,
        good: "The instructions appear consistent and do not conflict with each other.",
        improve: "The instructions should be checked for contradictions or mixed priorities."
      }
    }.freeze

    def initialize(prompt_analysis:, web_context: nil, fallback_reason: nil)
      @prompt_analysis = prompt_analysis
      @web_context = web_context
      @fallback_reason = fallback_reason
    end

    def call
      principles = principle_rows
      score = average_score(principles)

      {
        score: score,
        summary: summary(score),
        strengths: strengths(principles),
        weaknesses: weaknesses(principles),
        suggestions: suggestions(principles),
        analysis: {
          "provider" => "local",
          "fallback" => true,
          "fallback_reason" => fallback_reason,
          "web_context" => web_context,
          "principles" => principles
        }
      }
    end

    private

    attr_reader :prompt_analysis, :web_context, :fallback_reason

    def principle_rows
      PRINCIPLE_RULES.map do |name, rule|
        matched = prompt_text.match?(rule.fetch(:pattern))

        {
          "name" => name,
          "score" => principle_score(name, matched),
          "feedback" => principle_feedback(name, rule, matched)
        }
      end
    end

    def principle_feedback(name, rule, matched)
      return consistent_instructions? ? rule.fetch(:good) : rule.fetch(:improve) if name == "Don't Give Opposite Instructions"

      matched ? rule.fetch(:good) : rule.fetch(:improve)
    end

    def principle_score(name, matched)
      return consistent_instructions? ? 10.0 : 3.0 if name == "Don't Give Opposite Instructions"

      score = matched ? 8.0 : 2.5
      score += length_bonus
      score += 1.0 if name == "Be Clear About What You Want" && prompt_text.length >= PromptAnalysis::MIN_PROMPT_LENGTH
      [[score, 0].max, 10].min.round(1)
    end

    def length_bonus
      case prompt_text.length
      when 0...PromptAnalysis::MIN_PROMPT_LENGTH then -1.0
      when PromptAnalysis::MIN_PROMPT_LENGTH...160 then 0
      when 160...500 then 0.5
      else 1.0
      end
    end

    def consistent_instructions?
      prompt_text.exclude?("ignore tests") && prompt_text.exclude?("do not test")
    end

    def average_score(principles)
      total = principles.sum { |row| row.fetch("score") }
      BigDecimal((total / principles.size).round(1).to_s)
    end

    def summary(score)
      if score >= 8
        "This is a strong prompt by local checks. It gives clear direction and enough structure to guide a useful AI response."
      elsif score >= 6
        "This is a workable prompt by local checks. Add more context, constraints, and validation steps to make the response more reliable."
      else
        "This prompt needs more detail by local checks. Clarify the goal, provide context, define the expected output, and ask for checks."
      end
    end

    def strengths(principles)
      principles.select { |row| row.fetch("score") >= 7 }.first(5).map { |row| row.fetch("feedback") }
    end

    def weaknesses(principles)
      principles.select { |row| row.fetch("score") < 6 }.first(5).map { |row| row.fetch("feedback") }
    end

    def suggestions(principles)
      principles.select { |row| row.fetch("score") < 7 }.first(5).map { |row| row.fetch("feedback") }
    end

    def prompt_text
      prompt_analysis.prompt_text.to_s
    end
  end
end
