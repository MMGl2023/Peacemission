Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  match '/activate/:activation_code' => 'users#activate', via: %i[post get], defaults: { activation_code: nil }, as: :activate
  match '/signup/:invitation_code' => 'users#new', via: %i[post get], defaults: { invitation_code: nil }, as: :signup
  match '/signin' => 'sessions#new', via: %i[post get], as: :signin
  match '/signout' => 'sessions#destroy', via: %i[post get], as: :signout
  match '/forgot_password' => 'users#forgot_password', via: %i[post get], as: :forgot_password
  match '/reset_password/:password_reset_code' => 'users#reset_password', via: %i[post get], as: :reset_password

  resource :session

  resources :users do
    member do
      put 'suspend'
      put 'unsuspend'
      delete 'purge'
    end
    collection do
      get 'list'
      get 'home'
    end
  end

  resources :invitations do
    member do
      post 'send_inv'
    end
    collection do
      get 'list'
    end
  end

  resources :people do
    member do
      post 'props'
    end
    collection do
      get 'list'
      get 'recent_list'
      get 'recent2'
      get 'db_info'
      get 'dump'
      get :auto_complete_for_person_requests
      get :auto_complete_for_person_disappear_region
    end
  end

  resources :recent_people do
    member do
      post 'props'
    end
    collection do
      get 'list'
      get 'recent'
      get 'dump'
      get :auto_complete_for_recent_person_disappear_region
    end
  end

  match '/recent' => 'recent_people#recent', via: [:get, :post], as: :recent
  match '/people/recent' => 'recent_people#recent', via: [:get, :post], as: :recent2
  match '/people/recent_list' => 'recent_people#list', via: [:get, :post], as: :recent_list

  resources :ankets

  resources :requests do
    collection do
      get 'list'
    end
  end

  resources :losts do
    collection do
      get 'list'
    end
  end

  resources :fitems do
    member do
      get 'image'
    end
    collection do
      get 'list'
    end
  end

  resources :topics do
    member do
      post 'rollback'
      get 'show_auth'
    end
    collection do
      get 'list'
      match 'search', via: %i[get post]
      post 'birth'
      get 'news'
    end
  end

  resources :comments

  resources :reports do
    collection do
      get 'list'
    end
  end

  get 'message' => 'topics#message', as: :message
  get 'i/:name' => 'topics#show', as: :i
  get 'i_auth/:name' => 'topics#show_auth', as: :i_auth
  get 'news' => 'topics#news', as: :news
  post 'birth/:name' => 'topics#birth', as: :birth

  match 'as' => 'as/topic', via: :all, as: :as

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  root 'topics#show', name: :index, as: :index

  # Install the default routes as the lowest priority.
  match ':controller/:action/:id', via: :all
  match ':controller/:action/:id.:format', via: :all

  # See how all your routes lay out with "rake routes"
end
