require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category is valid" do
    category = Category.new(name: "Sústredenia", assembly: assemblies(:one))
    assert category.valid?
  end

  test "requires name" do
    category = Category.new(assembly: assemblies(:one))
    assert_not category.valid?
    assert_predicate category.errors[:name], :any?
  end

  test "requires unique name within assembly" do
    duplicate = Category.new(name: categories(:one).name, assembly: assemblies(:one))
    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:name], :any?
  end
end
