# frozen_string_literal: true

# rack-mini-profiler must never run in production: its badge HTML
# (e.g. "/blogs (99.1 ms)") gets indexed by Google as page snippets.
if defined?(Rack::MiniProfiler)
  Rack::MiniProfiler.config.enabled = Rails.env.development?
end
