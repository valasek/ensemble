require "test_helper"

class MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assembly = assemblies(:one)
    @member = members(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get assembly_members_url(@assembly)
    assert_response :success
  end

  test "should get show" do
    get assembly_member_url(@assembly, @member)
    assert_response :success
  end

  test "should get new" do
    get new_assembly_member_url(@assembly)
    assert_response :success
  end

  test "should create member" do
    assert_difference("Member.count") do
      post assembly_members_url(@assembly), params: { member: { name: "New Dancer" } }
    end
    assert_redirected_to assembly_member_url(@assembly, Member.last)
  end

  test "should not create member with invalid params" do
    assert_no_difference("Member.count") do
      post assembly_members_url(@assembly), params: { member: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_assembly_member_url(@assembly, @member)
    assert_response :success
  end

  test "should update member" do
    patch assembly_member_url(@assembly, @member), params: { member: { name: "Updated Name" } }
    assert_redirected_to assembly_member_url(@assembly, @member)
  end

  test "should not update member with invalid params" do
    patch assembly_member_url(@assembly, @member), params: { member: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "should destroy member" do
    assert_difference("Member.count", -1) do
      delete assembly_member_url(@assembly, @member)
    end
    assert_redirected_to assembly_members_url(@assembly)
  end
end
