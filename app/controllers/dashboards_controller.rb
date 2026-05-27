class DashboardsController < ApplicationController
  def show
    analyses = current_prompt_session.prompt_analyses.recent_first.limit(50)
    @dashboard = PromptPrinciplesDashboard.new(prompt_analyses: analyses).call
    @recent_analyses = analyses.select(&:completed?).first(10)
  end
end
