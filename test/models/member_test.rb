require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "valid member is valid" do
    member = Member.new(name: "Jana Novak", assembly: assemblies(:one))
    assert member.valid?
  end

  test "requires name" do
    member = Member.new(assembly: assemblies(:one))
    assert_not member.valid?
    assert_predicate member.errors[:name], :any?
  end

  test "requires assembly" do
    member = Member.new(name: "Jana Novak")
    assert_not member.valid?
    assert_not_empty member.errors[:assembly]
  end

  test "sorted_by_name returns members in case-insensitive alphabetical order" do
    sorted = assemblies(:one).members.sorted_by_name.to_a
    names = sorted.map(&:name)
    assert_equal names.sort_by(&:downcase), names
  end
end
