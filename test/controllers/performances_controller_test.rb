require "test_helper"

class PerformancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assembly = assemblies(:one)
    @performance = performances(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get assembly_performances_url(@assembly)
    assert_response :success
  end

  test "should get show" do
    get assembly_performance_url(@assembly, @performance)
    assert_response :success
  end

  test "should get new" do
    get new_assembly_performance_url(@assembly)
    assert_response :success
  end

  test "should create performance" do
    assert_difference("Performance.count") do
      post assembly_performances_url(@assembly), params: { performance: { name: "New Show", date: "2026-06-01", location: "Bratislava" } }
    end
    assert_redirected_to assembly_performance_url(@assembly, Performance.last)
  end

  test "should not create performance with invalid params" do
    assert_no_difference("Performance.count") do
      post assembly_performances_url(@assembly), params: { performance: { name: "", date: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_assembly_performance_url(@assembly, @performance)
    assert_response :success
  end

  test "should update performance" do
    patch assembly_performance_url(@assembly, @performance), params: { performance: { name: "Updated Show", date: @performance.date } }
    assert_redirected_to assembly_performance_url(@assembly, @performance)
  end

  test "should not update performance with invalid params" do
    patch assembly_performance_url(@assembly, @performance), params: { performance: { name: "", date: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy performance" do
    assert_difference("Performance.count", -1) do
      delete assembly_performance_url(@assembly, @performance)
    end
    assert_redirected_to assembly_performances_url(@assembly)
  end
end
