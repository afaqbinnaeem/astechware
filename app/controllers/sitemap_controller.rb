# frozen_string_literal: true

class SitemapController < ApplicationController
  layout false
  skip_before_action :verify_authenticity_token

  # ISO date used for static pages until per-page lastmod is available.
  SITE_LASTMOD = "2026-11-23"

  def index
    @urls = sitemap_urls
    respond_to do |format|
      format.xml { render content_type: "application/xml" }
    end
  end

  private

  def sitemap_urls
    base = if Rails.env.production?
             "https://astechware.com"
           else
             root_url.chomp("/")
           end

    urls = []
    urls.concat(core_page_urls(base))
    urls.concat(service_urls(base))
    urls.concat(solution_urls(base))
    urls.concat(hire_urls(base))
    urls.concat(integration_urls(base))
    urls.concat(case_study_urls(base))
    urls.concat(blog_urls(base))
    urls
  end

  def core_page_urls(base)
    paths = [
      ["", true],
      [about_path, route_defined?(:about_path)],
      [services_path, route_defined?(:services_path)],
      [contact_path, route_defined?(:contact_path)],
      [case_studies_path, route_defined?(:case_studies_path)],
      [reviews_path, route_defined?(:reviews_path)],
      [methodology_path, route_defined?(:methodology_path)],
      [gcc_path, route_defined?(:gcc_path)],
      [derisk_projects_path, route_defined?(:derisk_projects_path)],
      [blogs_path, route_defined?(:blogs_path)]
    ]

    paths.filter_map do |path, exists|
      next unless exists

      { loc: path.empty? ? base : "#{base}#{path}", lastmod: SITE_LASTMOD }
    end
  end

  def service_urls(base)
    named = %i[
      ai_agent_development_path
      machine_learning_path
      platform_modernization_path
      custom_software_path
      mvp_development_path
      api_integrations_path
      devops_engineering_path
    ]

    named.filter_map do |helper|
      next unless route_defined?(helper)

      { loc: "#{base}#{public_send(helper)}", lastmod: SITE_LASTMOD }
    end
  end

  def solution_urls(base)
    named = %i[
      industry_healthcare_path
      industry_legal_path
      industry_financial_path
      industry_b2b_saas_path
      industry_professional_services_path
      industry_edtech_path
      industry_construction_path
      industry_logistics_path
      industry_home_services_path
      industry_real_estate_path
      industry_private_clinics_path
      industry_fitness_studios_path
    ]

    named.filter_map do |helper|
      next unless route_defined?(helper)

      { loc: "#{base}#{public_send(helper)}", lastmod: SITE_LASTMOD }
    end
  end

  def hire_urls(base)
    named = %i[hire_ai_engineers_path hire_dedicated_developers_path]
    named.filter_map do |helper|
      next unless route_defined?(helper)

      { loc: "#{base}#{public_send(helper)}", lastmod: SITE_LASTMOD }
    end
  end

  def integration_urls(base)
    return [] unless route_defined?(:integrations_path)

    urls = [{ loc: "#{base}#{integrations_path}", lastmod: SITE_LASTMOD }]
    if defined?(IntegrationCatalog)
      IntegrationCatalog.slugs.each do |slug|
        next unless route_defined?(:integration_path)

        urls << { loc: "#{base}#{integration_path(slug)}", lastmod: SITE_LASTMOD }
      end
    end
    urls
  end

  def case_study_urls(base)
    return [] unless route_defined?(:case_study_path)

    CaseStudyCatalog.slugs.map do |slug|
      { loc: "#{base}#{case_study_path(slug)}", lastmod: SITE_LASTMOD }
    end
  end

  def blog_urls(base)
    blog_articles_list.filter_map do |article|
      path = article[:path].call
      lastmod = article[:updated_iso].presence || article[:date_iso].presence || SITE_LASTMOD
      { loc: "#{base}#{path}", lastmod: lastmod }
    end
  end

  def blog_articles_list
    view_context.blog_articles_list
  end

  def route_defined?(helper_name)
    Rails.application.routes.url_helpers.respond_to?(helper_name)
  end
end
