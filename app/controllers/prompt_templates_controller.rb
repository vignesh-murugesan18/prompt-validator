class PromptTemplatesController < ApplicationController
  def index
    @templates = PromptTemplate.where(public: true).order(:category, :title)
  end

  def show
    @template = PromptTemplate.find_by!(slug: params[:id], public: true)
  end
end

