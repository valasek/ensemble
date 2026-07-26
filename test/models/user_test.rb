require "test_helper"
require "ostruct"

class UserTest < ActiveSupport::TestCase
  test "from_omniauth creates new user when not found" do
    auth = OpenStruct.new(
      provider: "google_oauth2",
      uid: "brand-new-uid-99999",
      info: OpenStruct.new(email: "newuser@example.com")
    )
    assert_difference("User.count") do
      User.from_omniauth(auth)
    end
  end

  test "from_omniauth returns existing user on re-auth" do
    existing = users(:one)
    existing.update!(provider: "google_oauth2", uid: "existing-uid-123")
    auth = OpenStruct.new(
      provider: "google_oauth2",
      uid: "existing-uid-123",
      info: OpenStruct.new(email: existing.email)
    )
    assert_no_difference("User.count") do
      found = User.from_omniauth(auth)
      assert_equal existing.id, found.id
    end
  end

  test "email must be unique" do
    existing = users(:one)
    user = User.new(email: existing.email, password: "password123")
    assert_not user.valid?
    assert_not_empty user.errors[:email]
  end

  test "admin_for_avo? is true when user has assembly" do
    assert users(:one).admin_for_avo?
  end

  test "admin_for_avo? is false when user has no assembly and is not superadmin" do
    assert_not users(:two).admin_for_avo?
  end

  test "admin_for_avo? is true for superadmin email without assembly" do
    superadmin = User.new(
      email: User::SUPERADMIN_EMAIL,
      password: "password123",
      assembly: nil
    )

    assert superadmin.admin_for_avo?
  end
end
