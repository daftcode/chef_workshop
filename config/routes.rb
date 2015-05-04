Rails.application.routes.draw do
  resources :doges, only: [:new, :create]

  root 'doges#new'
end
