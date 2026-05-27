class PromptExperimentsController < ApplicationController
  VARIANT_LIMIT = 6

  def new
    @prompt_experiment = PromptExperiment.new(
      ai_model: Ai::PromptAnalyzer.default_model,
      web_search: false,
      status: "queued"
    )
    @variants = Array(params[:variants]).presence || ["", ""]
  end

  def create
    @prompt_experiment = PromptExperiment.new(prompt_experiment_params.merge(status: "queued"))
    variant_texts = variant_params

    if variant_texts.empty?
      @prompt_experiment.errors.add(:base, "Add at least one prompt variant to compare.")
      @variants = ["", ""]
      return render :new, status: :unprocessable_entity
    end

    PromptExperiment.transaction do
      @prompt_experiment.save!

      analyses = variant_texts.first(VARIANT_LIMIT).map do |text|
        PromptAnalysis.create!(
          prompt_experiment: @prompt_experiment,
          prompt_text: text,
          ai_model: @prompt_experiment.ai_model,
          web_search: @prompt_experiment.web_search,
          shared: false,
          status: "queued"
        )
      end

      analyses.each { |analysis| AnalyzePromptJob.perform_now(analysis) }
    end

    redirect_to @prompt_experiment
  rescue ActiveRecord::RecordInvalid => error
    @prompt_experiment = error.record.is_a?(PromptExperiment) ? error.record : @prompt_experiment
    @variants = variant_texts.presence || ["", ""]
    render :new, status: :unprocessable_entity
  end

  def show
    @prompt_experiment = PromptExperiment.includes(:prompt_analyses).find(params[:id])
    @prompt_experiment.refresh_status! if @prompt_experiment.prompt_analyses.any?
    @prompt_analyses = @prompt_experiment.prompt_analyses.order(:created_at)
  end

  private

  def prompt_experiment_params
    params.require(:prompt_experiment).permit(:title, :goal, :ai_model, :web_search).tap do |permitted|
      permitted[:ai_model] = Ai::PromptAnalyzer.default_model if permitted[:ai_model].blank?
      permitted[:web_search] = ActiveModel::Type::Boolean.new.cast(permitted[:web_search])
    end
  end

  def variant_params
    Array(params.dig(:prompt_experiment, :variants))
      .map { |text| text.to_s.strip }
      .reject(&:blank?)
  end
end

