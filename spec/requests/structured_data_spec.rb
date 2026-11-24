# frozen_string_literal: true

require "rails_helper"
require "nokogiri"
require "json"

RSpec.describe "Structured data", type: :request do
  def ld_blocks(html)
    Nokogiri::HTML(html).css('script[type="application/ld+json"]').map do |node|
      JSON.parse(node.text)
    end
  end

  def expect_one_organization(blocks, path)
    orgs = blocks.select { |b| b["@type"] == "Organization" || b["@id"].to_s.end_with?("#organization") }
    # Count top-level Organization types
    org_types = blocks.select { |b| b["@type"] == "Organization" }
    expect(org_types.length).to eq(1), "#{path}: expected exactly one Organization, got #{org_types.length}"
  end

  shared_examples "valid ld+json with one Organization" do |path|
    it "parses ld+json on #{path} with one Organization" do
      get path
      expect(response).to have_http_status(:ok)
      blocks = ld_blocks(response.body)
      expect(blocks).not_to be_empty
      blocks.each do |block|
        expect(block).to be_a(Hash)
      end
      expect_one_organization(blocks, path)
    end
  end

  include_examples "valid ld+json with one Organization", "/"
  include_examples "valid ld+json with one Organization", "/solutions/healthcare"

  it "parses ld+json on a case study with one Organization" do
    get "/case-studies/medical-voice-ai"
    expect(response).to have_http_status(:ok)
    blocks = ld_blocks(response.body)
    expect(blocks).not_to be_empty
    expect_one_organization(blocks, "/case-studies/medical-voice-ai")
  end

  it "parses ld+json on a blog post with one Organization" do
    get "/blogs/ai-chatbot-death-spiral"
    expect(response).to have_http_status(:ok)
    blocks = ld_blocks(response.body)
    expect(blocks).not_to be_empty
    expect_one_organization(blocks, "/blogs/ai-chatbot-death-spiral")
  end
end
