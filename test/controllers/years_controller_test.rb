require "test_helper"

class YearsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assembly = assemblies(:one)
  end

  test "should get index" do
    get assembly_years_url(@assembly)
    assert_response :success
  end

  test "should show year" do
    get assembly_year_url(@assembly, 2020)
    assert_response :success
  end

  test "should filter only all performances section by category" do
    get assembly_year_url(@assembly, 2020), params: { category_id: categories(:two).id }

    assert_response :success
    assert_includes @response.body, performances(:seven).name
    assert_includes @response.body, performances(:three).name
    assert_not_includes @response.body, performances(:eight).name
  end

  test "should redirect when year does not exist" do
    get assembly_year_url(@assembly, 2099)

    assert_redirected_to assembly_years_url(@assembly)
  end
end
