Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Backend only resources
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :forecast, only: :show, controller: "/forecasts"
      resources :addresses, only: :index, controller: "/addresses"
    end
  end

  # Frontend resources
  resource :forecast, only: :show
  resources :addresses, only: :index
  root "forecasts#new"
end
