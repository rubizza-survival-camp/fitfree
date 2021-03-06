# frozen_string_literal: true

Rails.application.routes.draw do
  # Error list
  match "/403", :to => "errors#forbidden", :via => :all
  match "/404", :to => "errors#not_found", :via => :all
  match "/422", :to => "errors#unprocessable_entity", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
  namespace :admin do
    resources :users do
      patch :block, on: :member
      patch :unblock, on: :member
      post :reset_password, on: :member
    end
    resources :administrators do
      patch :block, on: :member
      patch :unblock, on: :member
      post :reset_password, on: :member
    end
    root to: 'users#index'
  end
  root to: 'visitors#index'
  devise_for :users, path: 'users', controllers: { sessions: 'users/sessions', confirmations: 'users/confirmations' }
  devise_for :administrators,
             path: 'administrators',
             controllers: {sessions: 'administrators/sessions', confirmations: 'administrators/confirmations' }
  resources :users
  get '/locale', to: 'application#get_locale'
  get '/instruction', to: 'instruction#index'
  resources :trainings, except: :new
  get 'trainings/new/:date', to: 'trainings#new'
  put '/trainings/cancel/:id', to: 'trainings#cancel'
  resources :calendar, only: [:index, :new, :create]
  get '/redirect', to: 'calendar#redirect', as: 'redirect'
  get '/callback', to: 'calendar#callback', as: 'callback'
  get 'download', to: 'calendar#download'
  resources :exercise_types, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :exercises, except: :new
  get 'exercise/new/:id', to: 'exercises#new'
  resources :kits, except: :new
  get 'kits/new/:id', to: 'kits#new'
  post 'newkitform', to: 'kits#new_kit_form'
  post 'newexerciseform', to: 'exercises#new_exercise_form'
  resources :metrics

  post 'trainings/clients', to: 'trainings#join_clients'
  post 'trainings/exercises', to: 'trainings#exercises'

  mount ActionCable.server, at: '/cable'

  resources :clients do
    get 'payments/', to: 'payments#index'
    get 'payments/create'
    post 'payments/new', to: 'payments#add'
    get 'payments/:id/delete', to: 'payments#delete'
    get 'stats', to: 'clients#stats'
    get 'diary', to: 'clients#diary'
    resources :metrics, only: %i[index]
    resources :snapshots, shallow: true
    resources :messages
    post 'message/send', to: 'messages#send'
  end

  post 'webhooks/:id', to: 'webhooks#callback'
end
