class PromptSessionsController < ApplicationController
  def index
    @session = current_prompt_session
    @analyses = @session.prompt_analyses.recent_first.limit(50)
    @experiments = @session.prompt_experiments.order(created_at: :desc).limit(20)
  end

end
