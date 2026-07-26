require "test_helper"

class Search::ReindexAllTest < ActiveSupport::TestCase
  test "reindexes searchable models in the documented order" do
    calls = []

    with_stubbed_class_method(Member, :clear_index!, -> { calls << "Member.clear_index!" }) do
      with_stubbed_class_method(Performance, :clear_index!, -> { calls << "Performance.clear_index!" }) do
        with_stubbed_class_method(Performance, :reindex!, -> { calls << "Performance.reindex!" }) do
          with_stubbed_class_method(Member, :reindex!, -> { calls << "Member.reindex!" }) do
            result = Search::ReindexAll.call

            assert_equal [ "Member", "Performance" ], result
          end
        end
      end
    end

    assert_equal [
      "Member.clear_index!",
      "Performance.clear_index!",
      "Performance.reindex!",
      "Member.reindex!"
    ], calls
  end

  private

  def with_stubbed_class_method(klass, method_name, replacement)
    original_method = klass.method(method_name)
    klass.define_singleton_method(method_name, replacement)
    yield
  ensure
    klass.define_singleton_method(method_name, original_method)
  end
end
