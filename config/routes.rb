Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  resources :expenses, only: [ :index, :new, :create ]

  get 'dashboard' => 'misc#dashboard'
  get 'info' => 'misc#dashboard'

  get 'admin' => 'misc#admin'
  get 'cccdata' => 'misc#cccdata'

  root to: 'expenses#index'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
