# frozen_string_literal: true

SitemapGenerator::Sitemap.default_host = 'https://astechware.com'
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  add '/', priority: 1.0, changefreq: 'weekly'
  add '/services/ai-agent-development', priority: 0.9, changefreq: 'monthly'
  add '/services/machine-learning', priority: 0.9, changefreq: 'monthly'
  add '/services/platform-modernization', priority: 0.9, changefreq: 'monthly'
  add '/services/custom-software', priority: 0.9, changefreq: 'monthly'
  add '/services/api-integrations', priority: 0.8, changefreq: 'monthly'
  add '/services/devops-engineering', priority: 0.8, changefreq: 'monthly'
  add '/ai-agents', priority: 0.9, changefreq: 'monthly'
  add '/how-we-derisk-projects', priority: 0.7, changefreq: 'monthly'
  add '/solutions/healthcare', priority: 0.8, changefreq: 'monthly'
  add '/solutions/legal', priority: 0.8, changefreq: 'monthly'
  add '/solutions/financial', priority: 0.8, changefreq: 'monthly'
  add '/solutions/b2b-saas', priority: 0.8, changefreq: 'monthly'
  add '/solutions/professional-services', priority: 0.8, changefreq: 'monthly'
  add '/solutions/education-technology', priority: 0.8, changefreq: 'monthly'
  add '/methodology', priority: 0.7, changefreq: 'monthly'
  add '/case-studies', priority: 0.9, changefreq: 'weekly'
  add '/blogs', priority: 0.8, changefreq: 'weekly'
  add '/about', priority: 0.7, changefreq: 'monthly'
  add '/contact', priority: 0.8, changefreq: 'monthly'
  add '/clients', priority: 0.7, changefreq: 'monthly'
  add '/projects', priority: 0.8, changefreq: 'monthly'
  add '/privacy-policy', priority: 0.5, changefreq: 'monthly'
  add '/terms-of-service', priority: 0.5, changefreq: 'monthly'

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
    add "/case-studies/#{slug}", priority: 0.7, changefreq: 'monthly'
  end

  # All blog post pages (same source as ApplicationHelper#blog_articles_list)
  Object.new.extend(ApplicationHelper).blog_articles_list.each do |article|
    add "/blogs/#{article[:slug]}", priority: 0.7, changefreq: 'monthly'
  end
end
