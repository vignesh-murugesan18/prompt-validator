class NotificationPreferencesController < ApplicationController
  def edit
    @preference = current_notification_preference
    @session = current_prompt_session
  end

  def update
    @preference = current_notification_preference
    @session = current_prompt_session

    if @preference.update(preference_params)
      @session.link_email!(@preference.email) if @preference.email.present?

      redirect_to edit_notification_preference_path, notice: "Notification settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def preference_params
    params.require(:notification_preference).permit(
      :email,
      :digest_frequency,
      :notify_on_complete,
      :slack_webhook_url
    ).tap do |permitted|
      permitted[:notify_on_complete] = ActiveModel::Type::Boolean.new.cast(permitted[:notify_on_complete])
      permitted[:slack_webhook_url] = permitted[:slack_webhook_url].to_s.strip.presence
      permitted[:email] = permitted[:email].to_s.strip.presence
    end
  end
end
