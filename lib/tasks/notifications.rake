namespace :notifications do
  desc "Send daily digests now (for testing)"
  task daily: :environment do
    DispatchPromptDigestsJob.perform_now("daily")
    puts "Daily digest dispatch complete."
  end

  desc "Send weekly digests now (for testing)"
  task weekly: :environment do
    DispatchPromptDigestsJob.perform_now("weekly")
    puts "Weekly digest dispatch complete."
  end
end
