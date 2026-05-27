class DispatchPromptDigestsJob < ApplicationJob
  queue_as :default

  def perform(frequency = "daily")
    NotificationPreference.digest_enabled(frequency).find_each do |preference|
      next unless preference.due_for_digest?(frequency)

      SendPromptDigestJob.perform_later(preference.id, frequency: frequency)
    end
  end
end
