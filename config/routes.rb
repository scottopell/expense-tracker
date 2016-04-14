Rails.application.routes.draw do
  devise_for :users
  resources :expenses, only: [ :index, :new, :create ]
  get 'info' => 'expenses#user_info'
  get 'admin' => 'expenses#admin'
  get 'cccdata' => 'expenses#cccdata'

  root to: 'expenses#index'
end
