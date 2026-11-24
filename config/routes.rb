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
  post 'chat/message_new', to: 'chatbot_new#message'
  post 'chat/lead_new', to: 'chatbot_new#lead'
  get  'chat/history_new', to: 'chatbot_new#history'
  get '/ai-agents', to: redirect('/services/ai-agent-development', status: 301)
  get '/services/ai-agent-development', to: 'home#ai_agent_development', as: 'ai_agent_development'
  get '/services/machine-learning', to: 'home#machine_learning', as: 'machine_learning'
  get '/services/platform-modernization', to: 'home#platform_modernization', as: 'platform_modernization'
  get '/services/custom-software', to: 'home#custom_software', as: 'custom_software'
  get '/services/api-integrations', to: 'home#api_integrations', as: 'api_integrations'
  get '/services/devops-engineering', to: 'home#devops_engineering', as: 'devops_engineering'
  get '/clients', to: redirect('/reviews', status: 301), as: 'clients'
  get '/reviews', to: 'home#reviews', as: 'reviews'
  get '/about', to: 'home#about', as: 'about'
  get '/services', to: 'home#services', as: 'services'
  get '/case-studies', to: 'home#portfolio', as: 'case_studies'
  get '/case-studies/:slug', to: 'home#case_study', as: 'case_study'
  get '/integrations', to: 'integrations#index', as: 'integrations'
  get '/integrations/:slug', to: 'integrations#show', as: 'integration'
  get '/projects', to: redirect('/case-studies', status: 301), as: 'projects'
  get '/contact', to: 'home#contact', as: 'contact'
  get '/how-we-derisk-projects', to: 'home#derisk_projects', as: 'derisk_projects'
  get '/methodology', to: 'home#methodology', as: 'methodology'
  get '/gcc', to: 'home#gcc', as: 'gcc'
  get '/hire-ai-engineers', to: 'home#hire_ai_engineers', as: 'hire_ai_engineers'
  get '/hire-dedicated-developers', to: 'home#hire_dedicated_developers', as: 'hire_dedicated_developers'
  get '/solutions/healthcare', to: 'home#industry_healthcare', as: 'industry_healthcare'
  get '/solutions/legal', to: 'home#industry_legal', as: 'industry_legal'
  get '/solutions/financial', to: 'home#industry_financial', as: 'industry_financial'
  get '/solutions/b2b-saas', to: 'home#industry_b2b_saas', as: 'industry_b2b_saas'
  get '/solutions/professional-services', to: 'home#industry_professional_services', as: 'industry_professional_services'
  get '/solutions/education-technology', to: 'home#industry_edtech', as: 'industry_edtech'
  get '/solutions/construction', to: 'home#industry_construction', as: 'industry_construction'
  get '/solutions/logistics', to: 'home#industry_logistics', as: 'industry_logistics'
  get '/solutions/home-services', to: 'home#industry_home_services', as: 'industry_home_services'
  get '/solutions/real-estate', to: 'home#industry_real_estate', as: 'industry_real_estate'
  get '/solutions/private-clinics', to: 'home#industry_private_clinics', as: 'industry_private_clinics'
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
