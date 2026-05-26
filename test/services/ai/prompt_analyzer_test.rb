require "test_helper"

module Ai
  class PromptAnalyzerTest < ActiveSupport::TestCase
    FakeGroqClient = Data.define(:response) do
      def generate(prompt:)
        response
      end
    end

    FakePerplexityClient = Data.define(:response) do
      def search(query:)
        response
      end
    end

    RaisingGroqClient = Data.define(:message) do
      def generate(prompt:)
        raise GroqClient::Error, message
      end
    end

    test "normalizes a valid Groq JSON response" do
      prompt_analysis = PromptAnalysis.new(
        prompt_text: "You are a senior Rails engineer. Explain how to add background jobs with tests.",
        ai_model: "llama-3.1-8b-instant"
      )
      response = JSON.generate(
        score: 8.73,
        summary: "Clear and actionable.",
        strengths: ["Defines role", "Names framework"],
        weaknesses: ["Missing deployment context"],
        suggestions: ["Specify queue adapter"],
        principles: [
          { name: "Let the AI Ask Questions", score: 7.0, feedback: "Could invite clarifying questions." }
        ]
      )

      result = PromptAnalyzer.new(
        prompt_analysis: prompt_analysis,
        groq_client: FakeGroqClient.new(response),
        perplexity_client: FakePerplexityClient.new(nil)
      ).call

      assert_equal BigDecimal("8.7"), result[:score]
      assert_equal "Clear and actionable.", result[:summary]
      assert_equal ["Defines role", "Names framework"], result[:strengths]
      assert_equal ["Missing deployment context"], result[:weaknesses]
      assert_equal ["Specify queue adapter"], result[:suggestions]
      assert_equal "Let the AI Ask Questions", result[:analysis]["principles"].first["name"]
      assert_equal BigDecimal("7.0"), result[:analysis]["principles"].first["score"]
    end

    test "includes optional web context" do
      prompt_analysis = PromptAnalysis.new(
        prompt_text: "Compare current Rails background job options and recommend one for production.",
        ai_model: "llama-3.1-8b-instant",
        web_search: true
      )
      response = JSON.generate(
        score: 7.2,
        summary: "Good context.",
        strengths: ["Asks for a recommendation"],
        weaknesses: [],
        suggestions: ["Mention hosting constraints"],
        principles: [
          { name: "Let the AI Ask Questions", score: 6.0, feedback: "Could ask for more details first." }
        ]
      )

      result = PromptAnalyzer.new(
        prompt_analysis: prompt_analysis,
        groq_client: FakeGroqClient.new(response),
        perplexity_client: FakePerplexityClient.new("Recent Rails apps often use Solid Queue.")
      ).call

      assert_equal "Recent Rails apps often use Solid Queue.", result[:analysis]["web_context"]
    end

    test "raises a useful error for missing response keys" do
      prompt_analysis = PromptAnalysis.new(
        prompt_text: "Review this Rails route design and provide a concise improvement plan.",
        ai_model: "llama-3.1-8b-instant"
      )

      error = assert_raises(GroqClient::Error) do
        PromptAnalyzer.new(
          prompt_analysis: prompt_analysis,
          groq_client: FakeGroqClient.new(JSON.generate(score: 5.0)),
          perplexity_client: FakePerplexityClient.new(nil)
        ).call
      end

      assert_match "missed keys", error.message
    end

    test "falls back to local analysis when Groq quota is exceeded" do
      prompt_analysis = PromptAnalysis.new(
        prompt_text: "Act as a senior Rails engineer. Add tests, explain the plan, and verify the implementation step by step.",
        ai_model: "llama-3.1-8b-instant"
      )

      result = PromptAnalyzer.new(
        prompt_analysis: prompt_analysis,
        groq_client: RaisingGroqClient.new("Groq API error 429: rate limit exceeded"),
        perplexity_client: FakePerplexityClient.new(nil)
      ).call

      assert result[:score].positive?
      assert_equal true, result[:analysis]["fallback"]
      assert_equal "local", result[:analysis]["provider"]
      assert_equal PromptAnalyzer::PRINCIPLE_NAMES.size, result[:analysis]["principles"].size
      assert result[:summary].present?
    end
  end
end
