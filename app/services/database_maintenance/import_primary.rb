require "fileutils"
require "open3"
require "pathname"

module DatabaseMaintenance
  class ImportPrimary
    class Error < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(uploaded_file:, database_path: ExportPrimary.database_path, backup_directory: Rails.root.join("tmp", "database_import_backups"), backup_exporter: ExportPrimary)
      @uploaded_file = uploaded_file
      @database_path = Pathname(database_path)
      @backup_directory = Pathname(backup_directory)
      @backup_exporter = backup_exporter
    end

    def call
      ensure_development_environment!
      ensure_upload_present!
      ensure_integrity!(uploaded_path)
      ensure_schema_migrations!(uploaded_path)

      backup_path = backup_exporter.call(export_directory: backup_directory)

      ActiveRecord::Base.connection_handler.clear_all_connections!
      replace_database!
      ensure_integrity!(database_path)

      {
        backup_path: backup_path,
        database_path: database_path
      }
    end

    private

    attr_reader :uploaded_file, :database_path, :backup_directory, :backup_exporter

    def uploaded_path
      @uploaded_path ||= Pathname(uploaded_file.path)
    end

    def ensure_development_environment!
      return if Rails.env.development?

      raise Error, "Import databázy je povolený iba na vývojovom prostredí."
    end

    def ensure_upload_present!
      if uploaded_file.blank? || !uploaded_file.respond_to?(:path)
        raise Error, "Vyberte SQLite súbor na import."
      end

      return if uploaded_path.exist?

      raise Error, "Nahratý súbor sa nenašiel."
    end

    def ensure_schema_migrations!(path)
      result = run_sqlite3(path.to_s, "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'schema_migrations';")
      return if result == "schema_migrations"

      raise Error, "Súbor nevyzerá ako Rails databáza. Chýba tabuľka schema_migrations."
    end

    def ensure_integrity!(path)
      result = run_sqlite3(path.to_s, "PRAGMA integrity_check;")
      return if result == "ok"

      raise Error, "Kontrola integrity databázy zlyhala: #{result}"
    end

    def replace_database!
      FileUtils.mkdir_p(database_path.dirname)
      FileUtils.rm_f(sidecar_paths)
      FileUtils.cp(uploaded_path, database_path)
      FileUtils.rm_f(sidecar_paths)
    end

    def sidecar_paths
      [
        Pathname("#{database_path}-shm"),
        Pathname("#{database_path}-wal")
      ]
    end

    def run_sqlite3(file_path, command)
      stdout, stderr, status = Open3.capture3("sqlite3", file_path, command)
      return stdout.strip if status.success?

      raise Error, stderr.strip.presence || stdout.strip.presence || "sqlite3 command failed"
    end
  end
end
