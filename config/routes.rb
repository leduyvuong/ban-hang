# frozen_string_literal: true

Rails.application.routes.draw do
  root "pages#home"

  get "/health", to: "health#show"
  get "home", to: "pages#home"

  # Mount Action Cable for WebSocket connections
  mount ActionCable.server => "/cable"

  resources :products, only: %i[index show] do
    member do
      get :modal
    end

    resource :wishlist, only: %i[create destroy], module: :products
    resources :reviews, only: %i[create destroy], module: :products
  end

  resource :cart, only: %i[show], controller: "cart" do
    get :mini
    post :add_item
    patch :update_item
    delete :remove_item
    delete :clear
  end

  resource :checkout, only: %i[show update], controller: "checkout"
  resource :wishlist, only: :show
  resources :newsletter_subscriptions, only: :create

  resource :session, only: %i[new create destroy]
  resources :registrations, only: %i[new create], controller: "registrations"
  resource :profile, only: %i[edit update], controller: "registrations"
  resources :password_resets, only: %i[new create edit update], param: :token
  resources :orders, only: %i[index show]

  resources :conversations, only: %i[index show create] do
    resources :messages, only: :create
  end

  resource :support_chat, only: :show, controller: "support_chats"

  namespace :admin do
    root to: "dashboard#index"

    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout

    get "analytics", to: "analytics#index", as: :analytics
    resource :currency_selection, only: :create
    resources :currency_rates, except: %i[destroy show]
    resources :products
    resources :reviews, only: %i[index update destroy]
    resources :discounts do
      patch :toggle_active, on: :member
    end
    resources :orders, only: %i[index show]
    resources :customers do
      patch :block, on: :member
    end
    resources :shops, only: %i[index show] do
      resources :features, only: :index do
        post :unlock, on: :member
        post :lock, on: :member
      end
    end

    resource :storefront_settings, only: %i[show update], controller: "storefront_settings"

    get "messages", to: "messages#index"
    patch "messages/mark_all_read", to: "messages#mark_all_read", as: :messages_mark_all_read
    resources :conversations, only: [] do
      resources :messages, only: :create, controller: "conversation_messages"
    end
  end
end
