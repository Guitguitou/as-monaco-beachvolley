require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # Connecteur MCP du Staff (cf. docs/adr/0001) : OAuth, métadonnées, endpoint.
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications
  end
  get ".well-known/oauth-protected-resource(/mcp)", to: "well_known#protected_resource"
  get ".well-known/oauth-authorization-server", to: "well_known#authorization_server"
  post "mcp", to: "mcp#create"
  match "mcp", to: "mcp#method_not_allowed", via: [ :get, :delete ]

  # Mount Sidekiq Web UI (protected by authentication in routes)
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # Routes publiques pour les joueurs
  root "application#accueil"

  # Écran d'accueil du joueur connecté : sa prochaine session, son solde et les
  # sessions ouvertes pour lui. Remplace l'atterrissage sur les classements.
  get "mon-terrain", to: "home#show", as: :home
  # Vitrine de tous les composants (cf. UiKitController)
  get "ui-kit", to: "ui_kit#show", as: :ui_kit
  # Section Règles & informations
  scope :infos, controller: :infos do
    get "/", action: :index, as: :infos_root
    get "/videos", action: :videos, as: :infos_videos
    get "/planning-entrainements", action: :planning_trainings, as: :infos_planning_trainings
    get "/planning-saison", action: :planning_season, as: :infos_planning_season
    get "/reglement-interieur", action: :internal_rules, as: :infos_internal_rules
    get "/responsables-reservations", action: :reservations_leads, as: :infos_reservations_leads
    get "/plaquette-presentation", action: :brochure, as: :infos_brochure
    get "/regles-inscription", action: :registration_rules, as: :infos_registration_rules
  end
  resources :sessions do
    post :cancel, on: :member
    get :calendar, on: :member
    get :preview, on: :member
    resources :registrations, only: [ :create, :destroy ]
    resources :invitations, only: [ :create ], controller: "session_invitations"
  end

  # Annonces de jeu libre (« matcher » de joueurs)
  resources :annonces do
    member do
      get :confirm
      patch :confirm
      post :cancel
      post :toggle_availability
    end
  end

  resource :profile, only: [ :show, :update ], controller: "profiles"

  namespace :me do
    resources :sessions, only: [ :index, :show ]
  end

  get "performances", to: "performances#index", as: :performances

  namespace :coach do
    resources :trainings, only: [ :index ]
  end

  namespace :admin do
    root to: "dashboard#index"

    get "finances", to: "finances#show", as: :finances

    # Gestion de la saison (réinitialisation des licences)
    get "saison", to: "season#show", as: :season
    post "saison/reinitialiser", to: "season#reset", as: :reset_season

    # Règles du club (prix, inscriptions, désinscription)
    get "regles-du-club", to: "club_rules#edit", as: :club_rules
    patch "regles-du-club", to: "club_rules#update"

    resources :users do
      post :adjust_credits, on: :member
      post :disable, on: :member
      post :enable, on: :member
    end
    resources :sessions do
      post :duplicate, on: :member
    end
    resources :levels
    resources :groups, only: [ :index ]
    resources :claude_connections, only: [ :index, :destroy ], path: "connexions-claude"
    resources :terrains, except: [ :show ] do
      member do
        patch :move
        patch :archive
        patch :unarchive
      end
    end
    resources :terrain_closures, except: [ :show ]
    resources :public_pages, except: [ :show ], path: "pages-publiques"
    resources :stages, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :tournaments do
      member do
        patch :toggle_payment
        patch :reorder_images
        delete :remove_image
      end
    end

    # Packs management
    resources :packs

    # Purchase history
    resources :purchase_history, only: [ :index ] do
      collection do
        get :export
      end
    end

    # Boutique équipements : catalogue des articles (cf. GLOSSARY.md)
    scope "equipements" do
      resources :shop_campaigns, path: "campagnes", except: [ :show, :destroy ]
      resources :shop_products, path: "articles", except: [ :show, :destroy ] do
        resources :shop_cuts, path: "coupes", only: [ :create, :update, :destroy ]
        resources :shop_colors, path: "coloris", only: [ :create, :update, :destroy ]
      end
      resources :shop_size_guides, path: "guides-des-tailles", except: [ :show ]
    end
  end

  resources :tournaments, only: [ :index, :show ], path: "tournois"

  # Boutique équipements (cf. GLOSSARY.md) : le panier avant les articles,
  # pour que « panier » ne soit pas pris pour un identifiant d'article.
  scope "equipements" do
    resource :shop_cart, path: "panier", only: [ :show ]
    resources :shop_cart_lines, path: "panier/lignes", only: [ :create, :update, :destroy ]
  end
  resources :shop_products, path: "equipements", only: [ :index, :show ]

  # Public stages
  resources :stages, only: [ :index, :show ]

  # Packs (for users to buy)
  resources :packs, only: [ :index ] do
    post :buy, on: :member
  end

  # Retour de paiement Sherlock's. LCL n'a pas d'URL d'annulation : accepté,
  # refusé et annulé reviennent tous sur la même URL, en POST cross-site.
  # "checkout/success" reste un alias : il peut encore être renseigné dans
  # SHERLOCK_RETURN_URL_SUCCESS en production.
  match "checkout/return",  to: "checkout#create", via: [ :get, :post ], as: :checkout_return
  match "checkout/success", to: "checkout#create", via: [ :get, :post ], as: :checkout_success
  get "checkout/:id", to: "checkout#show", as: :checkout

  # Webhooks
  namespace :webhooks do
    post "sherlock", to: "sherlock#receive"
  end

  # Push notifications API
  namespace :api do
    resources :push_subscriptions, only: [ :create ] do
      collection do
        delete :destroy
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Manifest PWA (app/views/pwa/manifest.json.erb), lié dans layouts/_pwa_tags
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Pages publiques (web apps Google Apps Script) : à déclarer en dernier,
  # le slug ne doit masquer aucune autre route.
  get ":slug", to: "public_pages#show", as: :public_page, constraints: { slug: /[a-z0-9]+(?:-[a-z0-9]+)*/ }

  # Defines the root path route ("/")
  # root "posts#index"
end
