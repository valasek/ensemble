require "test_helper"

class PerformanceTest < ActiveSupport::TestCase
  test "valid performance is valid" do
    performance = Performance.new(name: "Gala Show", date: Date.today, assembly: assemblies(:one))
    assert performance.valid?
  end

  test "requires name" do
    performance = Performance.new(date: Date.today, assembly: assemblies(:one))
    assert_not performance.valid?
    assert_predicate performance.errors[:name], :any?
  end

  test "requires date" do
    performance = Performance.new(name: "Show", assembly: assemblies(:one))
    assert_not performance.valid?
    assert_predicate performance.errors[:date], :any?
  end

  test "requires assembly" do
    performance = Performance.new(name: "Show", date: Date.today)
    assert_not performance.valid?
    assert_not_empty performance.errors[:assembly]
  end
end
