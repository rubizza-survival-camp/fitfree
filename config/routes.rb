Rails.application.routes.draw do
  # namespace :admin do
  #     resources :users
  #     root to: "users#index"
  #   end
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :trainings, except: :new
  get 'trainings/new/:date', to: 'trainings#new'
  put '/trainings/cancel/:id', to: 'trainings#cancel'
  resources :calendar, only: [:index, :download]
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

  mount ActionCable.server => '/cable'
  resources :clients do
    get 'payments/', to: 'payments#index'
    get 'payments/create'
    post 'payments/new', to: 'payments#add'
    get 'stats', to: 'clients#stats'
    resources :metrics, only: [:index]
    resources :snapshots, shallow: true
    resources :messages
    post 'message/send', to: 'messages#send'
  end

  post 'webhooks/:id', to: 'webhooks#callback'

end
