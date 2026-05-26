require "net/http"
require "json"

module Ai
  class GroqClient
    class Error < StandardError; end

    API_HOST = "api.groq.com"

    def initialize(model_name: PromptAnalyzer.default_model, api_key: ENV["GROQ_API_KEY"])
      @model_name = model_name
      @api_key = api_key
    end

    def generate(prompt:)
      raise Error, "GROQ_API_KEY is not configured" if api_key.blank?

      response = post_json(uri, request_body(prompt))
      parse_text(response)
    end

    private

    attr_reader :model_name, :api_key

    def uri
      URI::HTTPS.build(
        host: API_HOST,
        path: "/openai/v1/chat/completions"
      )
    end

    def request_body(prompt)
      {
        model: model_name,
        messages: [
          {
            role: "system",
            content: "You are an expert AI prompt coach. Return only valid JSON."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.2,
        response_format: { type: "json_object" }
      }
    end

    def post_json(uri, payload)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 45) do |http|
        response = http.request(request)
        raise Error, "Groq API error #{response.code}: #{response.body.to_s.truncate(300)}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end
    rescue JSON::ParserError => error
      raise Error, "Groq returned invalid JSON: #{error.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise Error, "Groq request timed out"
    end

    def parse_text(response)
      text = response.dig("choices", 0, "message", "content").to_s.strip
      raise Error, "Groq returned an empty response" if text.blank?

      text
    end
  end
end
