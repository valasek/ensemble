require "test_helper"

class AssembliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assembly = assemblies(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get assemblies_url
    assert_response :success
  end

  test "should get show" do
    get assembly_url(@assembly)
    assert_response :success
  end

  test "should get new" do
    get new_assembly_url
    assert_response :success
  end

  test "should create assembly" do
    assert_difference("Assembly.count") do
      post assemblies_url, params: { assembly: { name: "New Ensemble", subdomain: "new-ensemble" } }
    end
    assert_redirected_to assembly_url(Assembly.last)
  end

  test "should not create assembly with invalid params" do
    assert_no_difference("Assembly.count") do
      post assemblies_url, params: { assembly: { name: "", subdomain: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_assembly_url(@assembly)
    assert_response :success
  end

  test "should update assembly" do
    patch assembly_url(@assembly), params: { assembly: { name: "Updated Name", subdomain: @assembly.subdomain } }
    assert_redirected_to assembly_url(@assembly)
  end

  test "should not update assembly with invalid params" do
    patch assembly_url(@assembly), params: { assembly: { name: "", subdomain: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy assembly" do
    assert_difference("Assembly.count", -1) do
      delete assembly_url(@assembly)
    end
    assert_redirected_to assemblies_url
  end
end
