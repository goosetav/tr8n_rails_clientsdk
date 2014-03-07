Rails.application.routes.draw do

  mount Tr8nClientSdk::Engine => "/tr8n_client_sdk"

  root :to => 'home#index'

  get 'home' => 'home#index'
  get 'home/index' => 'home#index'
  get 'home/upgrade_cache' => 'home#upgrade_cache'

  get 'docs/index' => 'docs#index'
  get 'docs/installation' => 'docs#installation'
  get 'docs/tml' => 'docs#tml'
  get 'docs/tml_content' => 'docs#tml_content'

end