# frozen_string_literal: true

# Return 410 Gone for junk URLs indexed while rack-mini-profiler ran in production.
# Match path prefixes only (suffixes and query strings vary).
class GonePaths
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"].to_s
    if path.start_with?("/mini-profiler-resources") || path.start_with?("/Date(")
      return [410, { "Content-Type" => "text/plain; charset=utf-8" }, ["Gone"]]
    end

    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before 0, GonePaths
