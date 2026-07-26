require "fileutils"
require "open3"
require "pathname"

module DatabaseMaintenance
  class ExportPrimary
    class Error < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(database_path: self.class.database_path, export_directory: Rails.root.join("tmp", "database_exports"), exported_path: nil)
      @database_path = Pathname(database_path)
      @export_directory = Pathname(export_directory)
      @exported_path = exported_path && Pathname(exported_path)
    end

    def self.database_path
      path = Pathname(ActiveRecord::Base.connection_db_config.database)
      path.absolute? ? path : Rails.root.join(path)
    end

    def call
      ensure_database_exists!
      FileUtils.mkdir_p(export_directory)

      run_sqlite3(database_path.to_s, ".backup #{target_path}")
      ensure_integrity!(target_path)

      target_path
    end

    private

    attr_reader :database_path, :export_directory, :exported_path

    def target_path
      @target_path ||= exported_path || export_directory.join(default_filename)
    end

    def default_filename
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      "ensemble-#{Rails.env}-primary-#{timestamp}.sqlite3"
    end

    def ensure_database_exists!
      return if database_path.exist?

      raise Error, "Databázový súbor sa nenašiel: #{database_path}"
    end

    def ensure_integrity!(path)
      result = run_sqlite3(path.to_s, "PRAGMA integrity_check;")
      return if result == "ok"

      raise Error, "Kontrola integrity exportu zlyhala: #{result}"
    end

    def run_sqlite3(file_path, command)
      stdout, stderr, status = Open3.capture3("sqlite3", file_path, command)
      return stdout.strip if status.success?

      raise Error, stderr.strip.presence || stdout.strip.presence || "sqlite3 command failed"
    end
  end
end
