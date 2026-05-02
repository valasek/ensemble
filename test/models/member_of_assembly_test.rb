require "test_helper"

class MemberOfAssemblyTest < ActiveSupport::TestCase
  test "valid record is valid" do
    record = MemberOfAssembly.new(member: members(:two), assembly: assemblies(:one), year: 2025)
    assert record.valid?
  end

  test "requires year" do
    record = MemberOfAssembly.new(member: members(:two), assembly: assemblies(:one))
    assert_not record.valid?
    assert_predicate record.errors[:year], :any?
  end

  test "year must be an integer" do
    record = MemberOfAssembly.new(member: members(:two), assembly: assemblies(:one), year: 2025.5)
    assert_not record.valid?
  end

  test "member cannot appear in same assembly, year, and group twice" do
    existing = member_of_assemblies(:one)
    duplicate = MemberOfAssembly.new(
      member: existing.member,
      assembly: existing.assembly,
      year: existing.year,
      group: existing.group
    )
    assert_not duplicate.valid?
    assert_not_empty duplicate.errors[:member_id]
  end

  test "same member can appear in same assembly in different years" do
    existing = member_of_assemblies(:one)
    record = MemberOfAssembly.new(
      member: existing.member,
      assembly: existing.assembly,
      year: 2099
    )
    assert record.valid?
  end
end
