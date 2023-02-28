ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  map.activate  '/activate/:activation_code', 
      :controller => 'users',     :action => 'activate', :activation_code => nil
  map.signup    '/signup/:invitation_code',   
      :controller => 'users',     :action => 'new', :invitation_code => nil
  map.signin    '/signin',   
      :controller => 'sessions',  :action => 'new'
  map.signout   '/signout',   
      :controller => 'sessions',  :action => 'destroy'
  map.forgot_password '/forgot_password', 
      :controller => 'users',     :action => 'forgot_password'
  map.reset_password '/reset_password/:password_reset_code', 
      :controller => 'users',     :action => 'reset_password'

    map.resource :session

  map.resources :users, 
      :member     => { :suspend => :put, :unsuspend => :put, :purge => :delete },
      :collection => { :list => :get, :home => :get }

  map.resources :invitations,
      :member     => { :send_inv => :post },
      :collection => { :list => :get }

  map.resources :people, 
      :member     => { :props => :post },
      :collection => { :list => :get, :recent_list => :get, :recent2 => :get, :db_info => :get, :dump => :get }

  map.resources :recent_people, 
      :member     => { :props => :post },
      :collection => { :list => :get, :recent => :get, :dump => :get }

  map.recent '/recent', :controller => 'recent_people',  :action => 'recent'
  map.recent2 '/people/recent', :controller => 'recent_people',  :action => 'recent'
  map.recent_list '/people/recent_list', :controller => 'recent_people',  :action => 'list'

  map.resources :ankets

  map.resources :requests, 
      :collection => { :list => :get }

  map.resources :losts, 
      :collection => { :list => :get }
  
  map.resources :fitems, 
      :member     => { :image => :get },
      :collection => { :list => :get }

  map.resources :topics,
      :member     => { :rollback => :post, :show_auth => :get },
      :collection => { :list => :get, :search => :get, :birth => :post, :news => :get }

  map.resources :comments

  map.resources :reports,
      :collection => { :list => :get }


  map.message 'message',        :action => 'message',   :controller => 'topics', :method => :get
  map.i       'i/:name',        :action => 'show',      :controller => 'topics', :method => :get
  map.i_auth  'i_auth/:name',   :action => 'show_auth', :controller => 'topics', :method => :get
  map.news    'news',           :action => 'news',      :controller => 'topics', :method => :get
  map.birth   'birth/:name',    :action => 'birth',     :controller => 'topics', :method => :post


  map.as 'as', :controller => 'as/topic'

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "topics", :action=>'show', :name => 'index'

	# Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  # See how all your routes lay out with "rake routes"
end

