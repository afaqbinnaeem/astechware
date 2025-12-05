# frozen_string_literal: true
Rails.application.routes.draw do
  devise_for :users
  resources :articles do
    resources :comments
  end
  resources :dashboard, only: [:index]
  resources :blogs, only: [:index]
  root 'home#index'
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  post 'submit_form', to: 'home#submit_form'
  get 'vestra-app-case-study', as: 'vestra_app_case_study', to: 'blogs#vestra_app_case_study'
  get 'whatsapp-voice-ai-agent-demo', as: 'whatsapp_voice_ai_agent_demo', to: 'blogs#whatsapp_voice_ai_agent_demo'
  get 'modular-ai-agents-case-study', as: 'modular_ai_agents_case_study', to: 'blogs#modular_ai_agents_case_study'

  get 'a-laymans-guide-for-hiring-a-top-software-company-in-pakistan', to: 'blogs#top_software_company_pk'
  get 'exploring-the-latest-web-development-trends-a-dive-into-rails-7-and-turbo', as: 'rails_7_and_turbo', to: 'blogs#rails_7_and_turbo'
  get 'top-5-startup-mistakes-to-avoid-learn-from-the-lessons-of-others', as: 'five_startup_mistakes', to: 'blogs#five_startup_mistakes'
  get '4-reasons-why-you-should-invest-in-a-new-website', as: 'four_reason_for_new_web', to: 'blogs#four_reason_for_new_web'
  get 'the-impact-of-ai-and-machine-learning-on-the-food-products-business', as: 'impact_of_ai_ml_on_food_industry', to: 'blogs#impact_of_ai_ml_on_food_industry'
end
