# frozen_string_literal: true
Rails.application.routes.draw do
  devise_for :users
  resources :articles do
    resources :comments
  end
  resources :dashboard, only: [:index]
  get 'blogs', to: 'blogs#index', as: 'blogs'
  get 'blogs/:slug', to: 'blogs#show', as: 'blog_show'
  get 'sitemap.xml', to: 'sitemap#index', format: 'xml', as: 'sitemap'
  root 'home#index'
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  post 'submit_form', to: 'home#submit_form'
  post 'chat/message', to: 'chat#message'
  get '/ai-agents', to: 'home#ai_agents', as: 'ai_agents'
  get '/services/ai-agent-development', to: 'home#ai_agent_development', as: 'ai_agent_development'
  get '/services/machine-learning', to: 'home#machine_learning', as: 'machine_learning'
  get '/services/platform-modernization', to: 'home#platform_modernization', as: 'platform_modernization'
  get '/services/custom-software', to: 'home#custom_software', as: 'custom_software'
  get '/services/api-integrations', to: 'home#api_integrations', as: 'api_integrations'
  get '/services/devops-engineering', to: 'home#devops_engineering', as: 'devops_engineering'
  get '/clients', to: 'home#clients', as: 'clients'
  get '/about', to: 'home#about', as: 'about'
  get '/case-studies', to: 'home#portfolio', as: 'case_studies'
  get '/projects', to: 'home#projects', as: 'projects'
  get '/contact', to: 'home#contact', as: 'contact'
  get '/how-we-derisk-projects', to: 'home#derisk_projects', as: 'derisk_projects'
  get '/methodology', to: 'home#methodology', as: 'methodology'
  get '/solutions/healthcare', to: 'home#industry_healthcare', as: 'industry_healthcare'
  get '/solutions/legal', to: 'home#industry_legal', as: 'industry_legal'
  get '/solutions/financial', to: 'home#industry_financial', as: 'industry_financial'
  get '/solutions/b2b-saas', to: 'home#industry_b2b_saas', as: 'industry_b2b_saas'
  get '/solutions/professional-services', to: 'home#industry_professional_services', as: 'industry_professional_services'
  get '/solutions/education-technology', to: 'home#industry_edtech', as: 'industry_edtech'
  get '/privacy-policy', to: 'home#privacy_policy', as: 'privacy_policy'
  get '/terms-of-service', to: 'home#terms_of_service', as: 'terms_of_service'
  get '/unsubscribe', to: 'home#unsubscribe', as: 'unsubscribe'
  get '/unsubscribe_me', to: 'home#unsubscribe_me', as: 'unsubscribe_me'
  # Redirect old blog URLs to /blogs/:slug (prevents 500s, preserves SEO)
  get 'vestra-app-case-study', to: redirect('/blogs/vestra-app-case-study')
  get 'whatsapp-voice-ai-agent-demo', to: redirect('/blogs/whatsapp-voice-ai-agent-demo')
  get 'modular-ai-agents-case-study', to: redirect('/blogs/modular-ai-agents-case-study')
  get 'a-laymans-guide-for-hiring-a-top-software-company-in-pakistan', to: redirect('/blogs/a-laymans-guide-for-hiring-a-top-software-company-in-pakistan')
  get 'exploring-the-latest-web-development-trends-a-dive-into-rails-7-and-turbo', to: redirect('/blogs/rails-7-and-turbo')
  get 'top-5-startup-mistakes-to-avoid-learn-from-the-lessons-of-others', to: redirect('/blogs/five-startup-mistakes')
  get '4-reasons-why-you-should-invest-in-a-new-website', to: redirect('/blogs/four-reason-for-new-web')
  get 'the-impact-of-ai-and-machine-learning-on-the-food-products-business', to: redirect('/blogs/impact-of-ai-ml-on-food-industry')
end
