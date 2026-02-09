# frozen_string_literal: true

return if Rails.env.development? || Rails.env.test?

APP_VERSION = File.read(Rails.root.join("VERSION")).strip rescue "0.0.0"
RELEASE_VERSION = "#{Rails.application.class.module_parent_name.downcase}@#{APP_VERSION}"

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn = 'https://d1c2684f36e399d3397f5c381b0183fd@o417369.ingest.us.sentry.io/4510856380481536' # rubocop:disable Style/StringLiterals
  config.traces_sample_rate = 1.0
  config.profiles_sample_rate = 1.0
  config.release = RELEASE_VERSION
end
