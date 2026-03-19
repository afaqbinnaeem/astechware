# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Railsondocker
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # When running in "static/no-DB" mode, avoid any ActiveRecord checks that
    # require a working database connection (pending migrations, etc.).
    config.active_record.migration_error = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.exceptions_app = self.routes

    # Rails 7 Host Authorization blocks requests with unexpected Host headers.
    # Allow your real domain(s) in production/static mode.
    config.hosts << "db956e321597.ngrok.app"
    ["astechware.com", "www.astechware.com"].each { |h| config.hosts << h }
    (ENV["ALLOWED_HOSTS"]&.split(",") || []).map(&:strip).reject(&:empty?).each do |h|
      config.hosts << h
    end

  end
end
