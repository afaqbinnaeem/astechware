# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Gone paths", type: :request do
  it "returns 410 for mini-profiler resource URLs" do
    get "/mini-profiler-resources/results?id=abc"
    expect(response).to have_http_status(:gone)
    expect(response.content_type).to include("text/plain")
  end

  it "returns 410 for /Date(...) junk URLs with trailing slash" do
    get "/Date(1775288805575)/"
    expect(response).to have_http_status(:gone)
  end

  it "returns 410 for /Date(...) junk URLs with query strings" do
    get "/Date(1775288805575)/?x=1"
    expect(response).to have_http_status(:gone)
  end

  it "returns 200 for the homepage" do
    get "/"
    expect(response).to have_http_status(:ok)
  end
end
