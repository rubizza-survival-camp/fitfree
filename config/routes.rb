Rails.application.routes.draw do
  namespace :admin do
      resources :users
      root to: "users#index"
    end
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :trainings
  resources :clients
  resources :calendar, only: [:index, :download]
  get 'download', to: 'calendar#download'
end
