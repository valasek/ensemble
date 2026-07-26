class Avo::ToolsController < Avo::ApplicationController
  def administration
    @page_title = "Správa dát"
    add_breadcrumb title: "Správa dát"
  end

  def reindex_all_data
    reindexed_models = ::Search::ReindexAll.call

    redirect_to avo.administration_path, flash: {
      success: {
        body: "Preindexované: #{reindexed_models.join(', ')}.",
        timeout: 5000
      }
    }
  rescue StandardError => exception
    Rails.logger.error(
      "Avo::ToolsController#reindex_all_data failed: #{exception.class}: #{exception.message}"
    )

    redirect_to avo.administration_path, flash: {
      error: {
        body: "Preindexovanie zlyhalo: #{exception.message}",
        timeout: :forever
      }
    }
  end

  def export_database
    exported_path = ::DatabaseMaintenance::ExportPrimary.call

    send_file exported_path,
      filename: exported_path.basename.to_s,
      type: "application/x-sqlite3",
      disposition: :attachment
  rescue StandardError => exception
    Rails.logger.error(
      "Avo::ToolsController#export_database failed: #{exception.class}: #{exception.message}"
    )

    redirect_to avo.administration_path, flash: {
      error: {
        body: "Export databázy zlyhal: #{exception.message}",
        timeout: :forever
      }
    }
  end

  def import_database
    result = ::DatabaseMaintenance::ImportPrimary.call(uploaded_file: params[:database_file])

    redirect_to avo.administration_path, flash: {
      success: {
        body: "Databáza bola importovaná. Záloha pôvodnej lokálnej DB: #{result[:backup_path].basename}.",
        timeout: :forever
      }
    }
  rescue StandardError => exception
    Rails.logger.error(
      "Avo::ToolsController#import_database failed: #{exception.class}: #{exception.message}"
    )

    redirect_to avo.administration_path, flash: {
      error: {
        body: "Import databázy zlyhal: #{exception.message}",
        timeout: :forever
      }
    }
  end
end
