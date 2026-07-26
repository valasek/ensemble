Rails.application.routes.draw do
  mount_avo do
    get "administration", to: "tools#administration", as: :administration
    post "administration/reindex_all_data", to: "tools#reindex_all_data", as: :administration_reindex_all_data
    post "administration/export_database", to: "tools#export_database", as: :administration_export_database
    post "administration/import_database", to: "tools#import_database", as: :administration_import_database
  end

  # mount Avo::Engine, at: "/admin"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  resources :assemblies do
    resources :members
    resources :member_of_ensembles
    resources :performances
    resources :years, only: [ :index, :show ]
  end

  post "search/proxy", to: "search#proxy"

  # public pages
  get "ensemble/home"
  get "ensemble/changelog"
  get "ensemble/contact"
  get "ensemble/pricing"
  get "ensemble/license"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "ensemble#home"
end
