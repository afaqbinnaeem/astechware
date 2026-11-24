# frozen_string_literal: true

require "rails_helper"
require "nokogiri"

RSpec.describe "SEO audit", type: :request do
  def strict?
    ENV["SEO_AUDIT_STRICT"].to_s == "1"
  end

  def report(message)
    if strict?
      raise message
    else
      warn "[seo_audit] #{message}"
    end
  end

  def sitemap_paths
    get "/sitemap.xml"
    expect(response).to have_http_status(:ok)
    doc = Nokogiri::XML(response.body)
    doc.xpath("//xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map do |node|
      uri = URI.parse(node.text)
      uri.path.presence || "/"
    end
  end

  it "checks titles, descriptions, H1s, and placeholders across sitemap URLs" do
    descriptions = {}
    paths = sitemap_paths

    paths.each do |path|
      get path
      unless response.successful? || response.status == 301 || response.status == 302
        report("#{path}: expected 2xx/3xx, got #{response.status}")
        next
      end
      next if response.status.in?([301, 302])

      html = response.body
      doc = Nokogiri::HTML(html)

      if html.include?("[[AHMAD")
        report("#{path}: rendered HTML contains [[AHMAD placeholder")
      end

      title = doc.at_css("title")&.text.to_s.strip
      if title.include?("A'sTechware | A'sTechware") || title.include?("| |")
        report("#{path}: broken title #{title.inspect}")
      end
      if title.length > 60
        report("#{path}: title length #{title.length} > 60 (#{title.inspect})")
      end

      desc = doc.at_css('meta[name="description"]')&.[]("content").to_s
      if desc.blank?
        report("#{path}: missing meta description")
      else
        if desc.length < 140 || desc.length > 165
          report("#{path}: description length #{desc.length} not in 140-165")
        end
        if descriptions[desc]
          report("#{path}: duplicate description also used on #{descriptions[desc]}")
        else
          descriptions[desc] = path
        end
      end

      page_h1s = doc.css("h1[data-page-h1]")
      if page_h1s.length != 1
        report("#{path}: expected exactly one h1[data-page-h1], found #{page_h1s.length}")
      end

      extra_h1s = doc.css("h1").reject { |h| h["data-page-h1"].present? }
      # Blog/case-study body content may contain extra h1s; warn only outside those.
      unless path.start_with?("/blogs/") || path.start_with?("/case-studies/")
        extra_h1s.each do |h|
          report("#{path}: extra <h1> outside page hero: #{h.text.to_s.strip.truncate(80).inspect}")
        end
      end
    end
  end
end
