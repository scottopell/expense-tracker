Rails.application.routes.draw do
  resources :expenses, only: [ :index, :new, :create ]
  get 'info' => 'expenses#user_info'
  get 'admin' => 'expenses#admin'
  get 'cccdata' => 'expenses#cccdata'

  root to: 'expenses#index'
end
