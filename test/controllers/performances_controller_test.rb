require "test_helper"

class PerformancesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get performances_index_url
    assert_response :success
  end

  test "should get show" do
    get performances_show_url
    assert_response :success
  end

  test "should get new" do
    get performances_new_url
    assert_response :success
  end

  test "should get create" do
    get performances_create_url
    assert_response :success
  end

  test "should get edit" do
    get performances_edit_url
    assert_response :success
  end

  test "should get update" do
    get performances_update_url
    assert_response :success
  end

  test "should get destroy" do
    get performances_destroy_url
    assert_response :success
  end
end
