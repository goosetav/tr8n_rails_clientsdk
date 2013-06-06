Rails.application.routes.draw do

  mount Tr8n::Engine => "/tr8n_client_sdk"

  root :to => 'home#index'

  match ':controller(/:action(/:id))(.:format)'
end
