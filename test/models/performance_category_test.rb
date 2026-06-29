require "test_helper"

class PerformanceCategoryTest < ActiveSupport::TestCase
  test "valid record is valid" do
    record = PerformanceCategory.new(performance: performances(:four), category: categories(:three))
    assert record.valid?
  end

  test "same performance-category pair must be unique" do
    existing = performance_categories(:one)
    duplicate = PerformanceCategory.new(performance: existing.performance, category: existing.category)

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:performance_id], :any?
  end
end
