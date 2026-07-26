require "test_helper"
require "tempfile"

class DatabaseMaintenance::ImportPrimaryTest < ActiveSupport::TestCase
  test "imports a validated sqlite file in development and backs up the current database" do
    uploaded_file = Tempfile.new([ "import-primary", ".sqlite3" ])
    database_path = Rails.root.join("tmp", "import-primary-target.sqlite3")
    backup_path = Rails.root.join("tmp", "before-import.sqlite3")
    calls = []
    success_status = Struct.new(:success?).new(true)
    backup_exporter = lambda do |export_directory:|
      calls << [ :backup_exporter, export_directory.to_s ]
      backup_path
    end

    File.write(uploaded_file.path, "sqlite")

    with_stubbed_class_method(Rails, :env, ActiveSupport::StringInquirer.new("development")) do
      with_stubbed_class_method(Open3, :capture3, lambda { |*args|
        calls << args

        case args[2]
        when "PRAGMA integrity_check;"
          [ "ok\n", "", success_status ]
        when "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'schema_migrations';"
          [ "schema_migrations\n", "", success_status ]
        else
          flunk "Unexpected sqlite3 call: #{args.inspect}"
        end
      }) do
        with_stubbed_instance_method(ActiveRecord::ConnectionAdapters::ConnectionHandler, :clear_all_connections!, -> { calls << [ :clear_all_connections ] }) do
          with_stubbed_class_method(FileUtils, :mkdir_p, ->(path) { calls << [ :mkdir_p, path.to_s ] }) do
            with_stubbed_class_method(FileUtils, :rm_f, ->(paths) { calls << [ :rm_f, Array(paths).map(&:to_s) ] }) do
              with_stubbed_class_method(FileUtils, :cp, ->(source, target) { calls << [ :cp, source.to_s, target.to_s ] }) do
                result = DatabaseMaintenance::ImportPrimary.call(
                  uploaded_file: uploaded_file,
                  database_path: database_path,
                  backup_directory: backup_path.dirname,
                  backup_exporter: backup_exporter
                )

                assert_equal backup_path, result[:backup_path]
                assert_equal database_path, result[:database_path]
              end
            end
          end
        end
      end
    end

    assert_equal [
      [ "sqlite3", uploaded_file.path, "PRAGMA integrity_check;" ],
      [ "sqlite3", uploaded_file.path, "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'schema_migrations';" ],
      [ :backup_exporter, backup_path.dirname.to_s ],
      [ :clear_all_connections ],
      [ :mkdir_p, database_path.dirname.to_s ],
      [ :rm_f, [ "#{database_path}-shm", "#{database_path}-wal" ] ],
      [ :cp, uploaded_file.path, database_path.to_s ],
      [ :rm_f, [ "#{database_path}-shm", "#{database_path}-wal" ] ],
      [ "sqlite3", database_path.to_s, "PRAGMA integrity_check;" ]
    ], calls
  ensure
    uploaded_file&.close!
  end

  test "rejects imports outside development" do
    with_stubbed_class_method(Rails, :env, ActiveSupport::StringInquirer.new("production")) do
      error = assert_raises(DatabaseMaintenance::ImportPrimary::Error) do
        DatabaseMaintenance::ImportPrimary.call(uploaded_file: nil)
      end

      assert_equal "Import databazy je povoleny iba v development prostredi.", error.message
    end
  end

  def with_stubbed_class_method(klass, method_name, replacement)
    original_method = klass.method(method_name)
    implementation = replacement.respond_to?(:call) ? replacement : -> { replacement }
    klass.define_singleton_method(method_name, implementation)
    yield
  ensure
    klass.define_singleton_method(method_name, original_method)
  end

  def with_stubbed_instance_method(klass, method_name, replacement)
    original_method = klass.instance_method(method_name)
    klass.define_method(method_name, replacement)
    yield
  ensure
    klass.define_method(method_name, original_method)
  end
end
