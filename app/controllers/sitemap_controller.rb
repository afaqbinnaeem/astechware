# frozen_string_literal: true

class SitemapController < ApplicationController
  layout false
  skip_before_action :verify_authenticity_token

  def index
    @urls = sitemap_urls
    respond_to do |format|
      format.xml { render content_type: "application/xml" }
    end
  end

  private

  def sitemap_urls
    # Match canonical_url: production uses canonical host, no trailing slashes
    base = if Rails.env.production?
             "https://astechware.com"
           else
             root_url.chomp("/")
           end
    urls = []

    # Homepage and main pages (use base for root so production has no trailing slash)
    urls << { loc: base, priority: "1.0", changefreq: "weekly" }
    urls << { loc: "#{base}#{about_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{contact_path}", priority: "0.8", changefreq: "monthly" }
    urls << { loc: "#{base}#{case_studies_path}", priority: "0.9", changefreq: "weekly" }
    urls << { loc: "#{base}#{clients_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{methodology_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{derisk_projects_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{blogs_path}", priority: "0.8", changefreq: "weekly" }
    urls << { loc: "#{base}#{privacy_policy_path}", priority: "0.5", changefreq: "monthly" }
    urls << { loc: "#{base}#{terms_of_service_path}", priority: "0.5", changefreq: "monthly" }

    # Service pages (0.9 for AI agents landing, 0.8 for individual services)
    urls << { loc: "#{base}#{ai_agents_path}", priority: "0.9", changefreq: "monthly" }
    urls << { loc: "#{base}#{ai_agent_development_path}", priority: "0.8", changefreq: "monthly" }
    urls << { loc: "#{base}#{machine_learning_path}", priority: "0.8", changefreq: "monthly" }
    urls << { loc: "#{base}#{platform_modernization_path}", priority: "0.8", changefreq: "monthly" }
    urls << { loc: "#{base}#{custom_software_path}", priority: "0.8", changefreq: "monthly" }
    urls << { loc: "#{base}#{api_integrations_path}", priority: "0.8", changefreq: "monthly" }
    urls << { loc: "#{base}#{devops_engineering_path}", priority: "0.8", changefreq: "monthly" }

    # Case study detail pages
    %w[
      medical-voice-ai
      shoreline-waste-logistics
      red-dragon-hvac
      vestra-payments
      zofi-cash-fintech
      instashowing-real-estate
      golfpay360-saas
      word-of-mouth-modernization
      restaurant-resource-rescue
      eventvesta-ai-marketing
      flss-legal-process-serving
      ai-deal-analyzer
    ].each do |slug|
      urls << { loc: "#{base}#{case_study_path(slug)}", priority: "0.7", changefreq: "monthly" }
    end

    # Industry / solution pages
    urls << { loc: "#{base}#{industry_healthcare_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{industry_legal_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{industry_financial_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{industry_b2b_saas_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{industry_professional_services_path}", priority: "0.7", changefreq: "monthly" }
    urls << { loc: "#{base}#{industry_edtech_path}", priority: "0.7", changefreq: "monthly" }

    # Blog posts
    blog_articles_list.each do |article|
      urls << { loc: "#{base}#{article[:path].call}", priority: "0.6", changefreq: "monthly" }
    end

    urls
  end

  def blog_articles_list
    view_context.blog_articles_list
  end
end
