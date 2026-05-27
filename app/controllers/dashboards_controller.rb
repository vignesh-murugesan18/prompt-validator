class DashboardsController < ApplicationController
  def show
    analyses = PromptAnalysis.where(visitor_token: current_visitor_token).recent_first.limit(50)
    @dashboard = PromptPrinciplesDashboard.new(prompt_analyses: analyses).call
    @recent_analyses = analyses.select(&:completed?).first(10)
  end
end

