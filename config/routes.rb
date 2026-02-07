require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  # Mount Sidekiq Web UI (protected by authentication in routes)
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Routes publiques pour les joueurs
  root "application#accueil"
  # Section Règles & informations
  scope :infos, controller: :infos do
    get '/', action: :index, as: :infos_root
    get '/videos', action: :videos, as: :infos_videos
    get '/planning-entrainements', action: :planning_trainings, as: :infos_planning_trainings
    get '/planning-saison', action: :planning_season, as: :infos_planning_season
    get '/reglement-interieur', action: :internal_rules, as: :infos_internal_rules
    get '/responsables-reservations', action: :reservations_leads, as: :infos_reservations_leads
    get '/plaquette-presentation', action: :brochure, as: :infos_brochure
    get '/regles-inscription', action: :registration_rules, as: :infos_registration_rules
  end
  resources :sessions do
    post :cancel, on: :member
    resources :registrations, only: [:create, :destroy]
  end

  resource :profile, only: [:show], controller: 'users'

  namespace :me do
    resources :sessions, only: [:index, :show]
  end

  get "performances", to: "performances#index", as: :performances

  namespace :coach do
    resources :trainings, only: [:index]
  end

  namespace :admin do
    root to: "dashboard#index"
    get "ui_kit", to: "ui_kit#index"

    resources :users do
      post :adjust_credits, on: :member
      post :disable, on: :member
      post :enable, on: :member
    end
    resources :sessions do
      post :duplicate, on: :member
    end
    resources :levels
    resources :stages, only: [:index, :show, :new, :create, :edit, :update]
    
    # Packs management
    resources :packs
    
    # Purchase history
    resources :purchase_history, only: [:index] do
      collection do
        get :export
      end
    end
    
    # Payments (deprecated - use packs)
    resource :payments, only: [:show] do
      post :buy_10_eur, on: :collection
    end
    
    # Notification rules management
    resources :notification_rules
  end
  
  # Public stages
  resources :stages, only: [:index, :show]
  
  # Packs (for users to buy)
  resources :packs, only: [:index] do
    post :buy, on: :member
  end
  
  # Checkout (success/cancel after payment)
  match 'checkout/success', to: 'checkout#success', via: [:get, :post], as: :checkout_success
  match 'checkout/cancel',  to: 'checkout#cancel',  via: [:get, :post], as: :checkout_cancel
  
  # Webhooks
  namespace :webhooks do
    post 'sherlock', to: 'sherlock#receive'
  end

  # Push notifications API
  namespace :api do
    resources :push_subscriptions, only: [:create] do
      collection do
        delete :destroy
      end
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
