require "json"

module Ai
  class PromptRewriter
    REQUIRED_KEYS = %w[rewrites].freeze

    def initialize(prompt_analysis:, strategy: "default", groq_client: nil)
      @prompt_analysis = prompt_analysis
      @strategy = strategy.to_s.presence || "default"
      @groq_client = groq_client || GroqClient.new(model_name: prompt_analysis.ai_model)
    end

    def call
      raw = groq_client.generate(prompt: rewrite_prompt)
      parsed = parse_response(raw)

      rewrites = Array(parsed["rewrites"]).filter_map do |row|
        next if row.blank?

        {
          "label" => row["label"].to_s.squish.presence || "Rewrite",
          "prompt_text" => row["prompt_text"].to_s.strip.presence
        }.compact
      end

      rewrites = rewrites.select { |row| row["prompt_text"].present? }.first(3)
      raise GroqClient::Error, "No rewrites were returned" if rewrites.empty?

      rewrites
    end

    private

    attr_reader :prompt_analysis, :strategy, :groq_client

    def rewrite_prompt
      summary = prompt_analysis.summary.to_s
      strengths = Array(prompt_analysis.strengths).join("\n- ").presence
      weaknesses = Array(prompt_analysis.weaknesses).join("\n- ").presence
      suggestions = Array(prompt_analysis.suggestions).join("\n- ").presence

      <<~PROMPT
        You are an expert AI prompt coach. Rewrite the USER PROMPT to be clearer, more actionable, and more complete for a coding AI assistant.

        Constraints:
        - Preserve the user's original intent. Do not change the task.
        - Keep it practical and concise, but include essential context, constraints, and a test/verification step when relevant.
        - Add a sentence encouraging clarifying questions when details are missing.
        - Output ONLY valid JSON.

        Strategy: #{strategy}

        Current analysis summary:
        #{summary.presence || "(none)"}

        Strengths:
        - #{strengths || "(none)"}

        Weaknesses:
        - #{weaknesses || "(none)"}

        Suggestions:
        - #{suggestions || "(none)"}

        Return JSON with this exact shape:
        {
          "rewrites": [
            { "label": "Most improved", "prompt_text": "..." },
            { "label": "More constraints", "prompt_text": "..." },
            { "label": "More step-by-step", "prompt_text": "..." }
          ]
        }

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
      raise GroqClient::Error, "Groq rewrite was not valid JSON: #{error.message}"
    end

    def extract_json(raw_response)
      stripped = raw_response.to_s.strip
      stripped = stripped.delete_prefix("```json").delete_prefix("```").delete_suffix("```").strip
      stripped[/\{.*\}/m] || stripped
    end
  end
end

