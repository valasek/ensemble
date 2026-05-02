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
end
