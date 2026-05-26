require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders the prompt coach homepage" do
    get root_path

    assert_response :success
    assert_select "h1", /Write AI Coding Prompts/
    assert_select "form[action='#{prompt_analyses_path}']"
  end
end
