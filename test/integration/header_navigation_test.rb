require "test_helper"

class HeaderNavigationTest < ActionDispatch::IntegrationTest
  test "does not show admin link for signed in user without assembly" do
    sign_in users(:two)

    get root_path
    follow_redirect!

    assert_response :success
    assert_select "a[href='/admin']", count: 0
  end

  test "shows admin link for signed in user with assembly" do
    sign_in users(:one)

    get root_path
    follow_redirect!

    assert_response :success
    assert_select "a[href='/admin']", minimum: 1
  end

  test "shows admin link for superadmin email without assembly" do
    superadmin = User.create!(
      email: User::SUPERADMIN_EMAIL,
      password: "password123",
      password_confirmation: "password123",
      assembly: nil
    )

    sign_in superadmin
    get root_path
    follow_redirect!

    assert_response :success
    assert_select "a[href='/admin']", minimum: 1
  end
end
