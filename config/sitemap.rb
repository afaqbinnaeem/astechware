# frozen_string_literal: true

SitemapGenerator::Sitemap.default_host = 'https://astechware.com'

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

  # Auto-include blog posts if there is a Post or Blog model
  # Post.find_each do |post|
  #   add "/blogs/#{post.slug}", lastmod: post.updated_at, priority: 0.7, changefreq: 'monthly'
  # end
end
