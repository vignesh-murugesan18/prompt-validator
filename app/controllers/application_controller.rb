class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_visitor_token
    session[:visitor_token] ||= SecureRandom.hex(16)
  end

  def current_prompt_session
    @current_prompt_session ||= PromptSession.find_or_create_by!(visitor_token: current_visitor_token) do |record|
      record.last_activity_at = Time.current
    end.tap(&:touch_last_activity!)
  end

  def current_notification_preference
    current_prompt_session.notification_preference ||
      current_prompt_session.create_notification_preference!(digest_frequency: "none")
  end
end
