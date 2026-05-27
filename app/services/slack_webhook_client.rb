require "net/http"
require "json"

class SlackWebhookClient
  class Error < StandardError; end

  def initialize(webhook_url:)
    @webhook_url = webhook_url.to_s.strip
  end

  def post_text(text)
    return if webhook_url.blank?

    uri = URI.parse(webhook_url)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate({ text: text.to_s.truncate(3_000) })

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
      response = http.request(request)
      raise Error, "Slack webhook error #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    end
  rescue URI::InvalidURIError
    raise Error, "Slack webhook URL is invalid"
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise Error, "Slack webhook request timed out"
  end

  private

  attr_reader :webhook_url
end
