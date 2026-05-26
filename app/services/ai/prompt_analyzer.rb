require "json"

module Ai
  class PromptAnalyzer
    REQUIRED_KEYS = %w[score summary strengths weaknesses suggestions principles].freeze
    PRINCIPLE_NAMES = [
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

    def self.default_model
      ENV.fetch("GROQ_MODEL", "llama-3.1-8b-instant")
    end

    def initialize(prompt_analysis:, groq_client: nil, perplexity_client: nil)
      @prompt_analysis = prompt_analysis
      @groq_client = groq_client || GroqClient.new(model_name: prompt_analysis.ai_model)
      @perplexity_client = perplexity_client || PerplexityClient.new
    end

    def call
      web_context = fetch_web_context
      raw_response = begin
        groq_client.generate(prompt: analysis_prompt(web_context))
      rescue GroqClient::Error => error
        return local_fallback(web_context, error) if fallback_error?(error)

        raise
      end
      parsed = parse_response(raw_response)

      {
        score: normalize_score(parsed["score"]),
        summary: parsed["summary"].to_s.squish,
        strengths: normalize_list(parsed["strengths"]),
        weaknesses: normalize_list(parsed["weaknesses"]),
        suggestions: normalize_list(parsed["suggestions"]),
        analysis: parsed.merge(
          "principles" => normalize_principles(parsed["principles"]),
          "web_context" => web_context,
          "raw_response" => raw_response
        )
      }
    end

    private

    attr_reader :prompt_analysis, :groq_client, :perplexity_client

    def fetch_web_context
      return nil unless prompt_analysis.web_search?

      perplexity_client.search(query: prompt_analysis.prompt_text)
    rescue PerplexityClient::Error => error
      "Web search failed: #{error.message}"
    end

    def analysis_prompt(web_context)
      <<~PROMPT
        You are a strict AI prompt coach. Score the USER PROMPT from 0.0 to 10.0 for how likely it is to produce a precise, useful result from a coding AI assistant.

        Scoring rules:
        - Be strict. Do not give high scores for implied intent.
        - 0.0 means absent or directly harmful.
        - 1.0 to 3.0 means mostly missing.
        - 4.0 to 6.0 means partially present but weak.
        - 7.0 to 8.0 means present and useful, but not excellent.
        - 9.0 means explicit and strong.
        - 10.0 means explicit, complete, and hard to improve.
        - Score "Let the AI Ask Questions" below 4 unless the prompt explicitly asks the AI to ask clarifying questions before answering or coding.
        - Score "Ask the AI to Think Out Loud" below 5 unless the prompt explicitly asks for reasoning, a plan, tradeoffs, or step-by-step thinking before the solution.
        - Score "Don't Give Opposite Instructions" high only when the prompt is internally consistent and has no conflicting requirements.

        For each principle, write feedback in this style:
        - One direct sentence.
        - Mention what is missing when the score is low.
        - Mention what is strong when the score is high.
        - Use language like: "No additional guidance..." or "The request clearly..."

        Return only valid JSON with this exact shape:
        {
          "score": 7.4,
          "summary": "One concise paragraph.",
          "strengths": ["Specific strength"],
          "weaknesses": ["Specific weakness"],
          "suggestions": ["Concrete improvement"],
          "principles": [
            { "name": "Let the AI Ask Questions", "score": 7.0, "feedback": "One sentence about this principle." }
          ]
        }

        Include one principles item for each of these exact principle names, preserving order:
        #{PRINCIPLE_NAMES.map { |name| "- #{name}" }.join("\n")}

        Principle definitions:
        - Let the AI Ask Questions: whether the prompt tells the AI to ask clarifying questions before answering when details are missing.
        - Ask the AI to Think Out Loud: whether it asks for reasoning, a plan, tradeoffs, or step-by-step thinking before code or conclusions.
        - Take It One Step at a Time: whether it breaks the work into ordered, sequential steps.
        - Point to Code That Works: whether it references existing code, examples, known-good patterns, or expected outputs.
        - Name Your Tools and Versions: whether it names frameworks, libraries, languages, tools, versions, APIs, or environment details.
        - Explain Your Situation: whether it explains context, background, current behavior, and why the task matters.
        - Be Clear About What You Want: whether it states the desired outcome clearly and specifically.
        - Show What You're Looking For: whether it includes examples, screenshots, target behavior, or concrete acceptance examples.
        - Tell the AI Who to Be: whether it assigns a useful role or persona.
        - Say How You Want the Answer: whether it specifies response format, style, depth, or output structure.
        - Organize Your Request Clearly: whether it is structured with sections, bullets, numbered steps, or clear grouping.
        - Plan for Things Going Wrong: whether it includes error handling, fallback behavior, tests, validation, or failure modes.
        - Think About Weird Situations: whether it covers edge cases, unusual inputs, exceptions, or surprising scenarios.
        - Don't Give Opposite Instructions: whether the instructions avoid contradictions and mixed priorities.

        #{web_context.present? ? "Current web context:\n#{web_context}\n" : ""}
        USER PROMPT:
        #{prompt_analysis.prompt_text}
      PROMPT
    end

    def parse_response(raw_response)
      json_text = extract_json(raw_response)
      parsed = JSON.parse(json_text)
      missing_keys = REQUIRED_KEYS - parsed.keys
      raise GroqClient::Error, "Groq response missed keys: #{missing_keys.join(', ')}" if missing_keys.any?

      parsed
    rescue JSON::ParserError => error
      raise GroqClient::Error, "Groq analysis was not valid JSON: #{error.message}"
    end

    def extract_json(raw_response)
      stripped = raw_response.to_s.strip
      stripped = stripped.delete_prefix("```json").delete_prefix("```").delete_suffix("```").strip
      stripped[/\{.*\}/m] || stripped
    end

    def normalize_score(value)
      score = BigDecimal(value.to_s)
      [[score, 0].max, 10].min.round(1)
    rescue ArgumentError
      raise GroqClient::Error, "Groq score was not numeric"
    end

    def normalize_list(value)
      Array(value).map { |item| item.to_s.squish }.reject(&:blank?).first(5)
    end

    def normalize_principles(value)
      indexed_rows = Array(value).index_by { |row| row["name"].to_s.squish }

      PRINCIPLE_NAMES.map do |name|
        row = indexed_rows[name] || {}

        {
          "name" => name,
          "score" => normalize_score(row.fetch("score", 0)),
          "feedback" => row["feedback"].to_s.squish.presence || "No detailed feedback returned for this principle."
        }
      end
    end

    def fallback_error?(error)
      error.message.match?(/429|quota|rate limit|GROQ_API_KEY is not configured/i)
    end

    def local_fallback(web_context, error)
      LocalPromptAnalyzer.new(
        prompt_analysis: prompt_analysis,
        web_context: web_context,
        fallback_reason: error.message
      ).call
    end
  end
end
