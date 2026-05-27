class PromptTemplate < ApplicationRecord
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :category, presence: true
  validates :prompt_text, presence: true, length: { maximum: 20_000 }
end

