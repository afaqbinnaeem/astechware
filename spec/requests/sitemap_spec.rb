# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sitemap", type: :request do
  it "returns application/xml with healthcare solution URL" do
    get "/sitemap.xml"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/xml")
    expect(response.body).to include("https://astechware.com/solutions/healthcare").or include("/solutions/healthcare")
    expect(response.body).not_to include("<priority>")
    expect(response.body).not_to include("<changefreq>")
  end
end
