require "net/http"
require "json"

module Ai
  class PerplexityClient
    class Error < StandardError; end

    API_URI = URI("https://api.perplexity.ai/chat/completions")

    def initialize(api_key: ENV["PERPLEXITY_API_KEY"], model: ENV.fetch("PERPLEXITY_MODEL", "sonar-pro"))
      @api_key = api_key
      @model = model
    end

    def search(query:)
      return "Web search was requested, but PERPLEXITY_API_KEY is not configured." if api_key.blank?

      response = post_json(request_body(query))
      response.dig("choices", 0, "message", "content").to_s.strip.presence
    end

    private

    attr_reader :api_key, :model

    def request_body(query)
      {
        model: model,
        messages: [
          {
            role: "system",
            content: "Find concise, current context that helps evaluate whether a user's AI prompt is specific, actionable, and complete."
          },
          {
            role: "user",
            content: query.truncate(2_000)
          }
        ],
        temperature: 0.1
      }
    end

    def post_json(payload)
      request = Net::HTTP::Post.new(API_URI)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      Net::HTTP.start(API_URI.host, API_URI.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
        response = http.request(request)
        raise Error, "Perplexity API error #{response.code}: #{response.body.to_s.truncate(300)}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end
    rescue JSON::ParserError => error
      raise Error, "Perplexity returned invalid JSON: #{error.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise Error, "Perplexity request timed out"
    end
  end
end
