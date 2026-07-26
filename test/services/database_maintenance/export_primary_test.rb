require "test_helper"
require "tmpdir"

class DatabaseMaintenance::ExportPrimaryTest < ActiveSupport::TestCase
  test "exports the primary database and validates the snapshot" do
    source_path = Rails.root.join("tmp", "export-primary-source.sqlite3")
    export_path = Rails.root.join("tmp", "export-primary-target.sqlite3")
    calls = []
    success_status = Struct.new(:success?).new(true)

    File.write(source_path, "sqlite")

    with_stubbed_class_method(FileUtils, :mkdir_p, ->(path) { calls << [ :mkdir_p, path.to_s ] }) do
      with_stubbed_class_method(Open3, :capture3, lambda { |*args|
        calls << args

        case args[2]
        when ".backup #{export_path}"
          [ "", "", success_status ]
        when "PRAGMA integrity_check;"
          [ "ok\n", "", success_status ]
        else
          flunk "Unexpected sqlite3 call: #{args.inspect}"
        end
      }) do
        result = DatabaseMaintenance::ExportPrimary.call(
          database_path: source_path,
          export_directory: export_path.dirname,
          exported_path: export_path
        )

        assert_equal export_path, result
      end
    end

    assert_equal [
      [ :mkdir_p, export_path.dirname.to_s ],
      [ "sqlite3", source_path.to_s, ".backup #{export_path}" ],
      [ "sqlite3", export_path.to_s, "PRAGMA integrity_check;" ]
    ], calls
  ensure
    FileUtils.rm_f(source_path)
    FileUtils.rm_f(export_path)
  end

  def with_stubbed_class_method(klass, method_name, replacement)
    original_method = klass.method(method_name)
    implementation = replacement.respond_to?(:call) ? replacement : -> { replacement }
    klass.define_singleton_method(method_name, implementation)
    yield
  ensure
    klass.define_singleton_method(method_name, original_method)
  end
end
