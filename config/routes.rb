Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  resources :expenses, only: [ :index, :new, :create ]

  get 'dashboard' => 'misc#dashboard'
  get 'info' => 'misc#dashboard'

  get 'admin' => 'misc#admin'
  get 'admin/user_viewer' => 'misc#admin_user_viewer'
  get 'admin/password_reset' => 'misc#admin_password_reset'
  get 'cccdata' => 'misc#cccdata'

  post 'admin/drop_data' => 'misc#drop_data'
  post 'admin/password_reset' => 'misc#admin_password_reset_post'

  root to: 'expenses#index'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
