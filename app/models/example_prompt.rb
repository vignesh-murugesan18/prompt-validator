class ExamplePrompt < ApplicationRecord
  validates :title, presence: true
  validates :prompt_text, presence: true
  validates :position, numericality: { only_integer: true }
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true

  default_scope { order(position: :asc, created_at: :asc) }
end
