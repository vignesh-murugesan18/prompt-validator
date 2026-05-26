require "test_helper"

class PromptAnalysisTest < ActiveSupport::TestCase
  test "requires a useful prompt length" do
    analysis = PromptAnalysis.new(prompt_text: "too short", ai_model: "llama-3.1-8b-instant")

    assert_not analysis.valid?
    assert_includes analysis.errors[:prompt_text], "is too short (minimum is 40 characters)"
  end

  test "recognizes pending statuses" do
    analysis = PromptAnalysis.new(status: "queued")

    assert analysis.pending?

    analysis.status = "processing"
    assert analysis.pending?

    analysis.status = "completed"
    assert_not analysis.pending?
  end

  test "truncates prompt previews" do
    analysis = PromptAnalysis.new(prompt_text: "Write a detailed Rails implementation plan with tests and deployment notes.")

    assert_equal "Write a detailed Rails...", analysis.prompt_preview(25)
  end
end
