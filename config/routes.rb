# frozen_string_literal: true

Rails.application.routes.draw do
  root "pages#home"
  get "home", to: "pages#home"

  resources :products, only: %i[index show] do
    member do
      get :modal
    end
  end

  resource :cart, only: %i[show], controller: "cart" do
    get :mini
    post :add_item
    patch :update_item
    delete :remove_item
    delete :clear
  end

  resource :checkout, only: %i[show update], controller: "checkout"
  resources :newsletter_subscriptions, only: :create

  resource :session, only: %i[new create destroy]
  resources :registrations, only: %i[new create], controller: "registrations"
  resource :profile, only: %i[edit update], controller: "registrations"
  resources :password_resets, only: %i[new create edit update], param: :token
  resources :orders, only: %i[index show]

  namespace :admin do
    root to: "dashboard#index"

    resources :products
    resources :orders, only: %i[index show]
  end
end
