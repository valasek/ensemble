require "test_helper"

class AssemblyTest < ActiveSupport::TestCase
  test "valid assembly is valid" do
    assembly = Assembly.new(name: "Test Ensemble", subdomain: "test-ensemble")
    assert assembly.valid?
  end

  test "requires name" do
    assembly = Assembly.new(subdomain: "test")
    assert_not assembly.valid?
    assert_predicate assembly.errors[:name], :any?
  end

  test "requires subdomain" do
    assembly = Assembly.new(name: "Test")
    assert_not assembly.valid?
    assert_predicate assembly.errors[:subdomain], :any?
  end

  test "name must be unique" do
    existing = assemblies(:one)
    assembly = Assembly.new(name: existing.name, subdomain: "other")
    assert_not assembly.valid?
    assert_predicate assembly.errors[:name], :any?
  end

  test "subdomain must be unique case-insensitively" do
    existing = assemblies(:one)
    assembly = Assembly.new(name: "Another", subdomain: existing.subdomain.upcase)
    assert_not assembly.valid?
  end

  test "subdomain only allows lowercase letters, digits, and hyphens" do
    assembly = Assembly.new(name: "Bad", subdomain: "UPPER_CASE")
    assert_not assembly.valid?
    assert_not_empty assembly.errors[:subdomain]
  end

  test "reserved subdomains are rejected" do
    %w[www admin support mail help].each do |reserved|
      assembly = Assembly.new(name: "X #{reserved}", subdomain: reserved)
      assert_not assembly.valid?, "expected #{reserved} to be rejected"
    end
  end

  test "subdomain with uppercase is rejected by format validation" do
    assembly = Assembly.new(name: "Cased Ensemble", subdomain: "CasedSub")
    assert_not assembly.valid?
    assert_predicate assembly.errors[:subdomain], :any?
  end
end
