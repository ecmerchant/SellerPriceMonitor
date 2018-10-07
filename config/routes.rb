require 'resque/server'

Rails.application.routes.draw do

  root to: 'products#show'

  get 'products/show'

  get 'products/setup'
  post 'products/setup'

  post 'products/upload'
  post 'products/price_upload'

  post 'products/update'

  get 'products/revise'
  post 'products/revise'

  get 'products/check'

  get 'products/report'

  get 'products/reset'

  delete 'products/delete'
  mount Resque::Server.new, at: "/resque"

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/sign_in' => 'devise/sessions#new'
  end
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {
   :registrations => 'users/registrations'
  }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
