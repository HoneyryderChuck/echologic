#
# Rails routing guide: http://guides.rubyonrails.org/routing.html
#
Echologic::Application.routes.draw do

  # routing-filter plugin for wrapping :locale around urls and paths.
  filter :locale


  # SECTION main parts of echologic
  match '/act/roadmap' => 'act#roadmap', :as => :act
  match '/discuss/featured' => 'discuss#index', :as => :discuss
  match '/discuss/roadmap' => 'discuss#roadmap', :as => :discuss_roadmap
  match '/discuss/search' => 'questions#category', :as => :discuss_search
  match '/discuss/cancel' => 'discuss#cancel', :as => :discuss_cancel
  match '/discuss/category/:id' => 'questions#category', :as => :question_tags, :conditions => {:id => /\w+/ }
  match '/discuss/my_discussions' => 'questions#my_discussions', :as => :my_discussions

  match '/connect/roadmap' => 'connect#roadmap', :as => :connect_roadmap

  match '/my_echo/roadmap' => 'my_echo#roadmap', :as => :my_echo

  resource :connect, :only => [:show]
  resource :admin,   :only => [:show]

  # SECTION my echo routing
  match 'my_profile' => 'my_echo#profile', :as => :my_profile
  
  match '/profiles/:id/details' => 'users/profile#details', :as => :profile_details
  
  match 'welcome' => 'my_echo#welcome', :as => :welcome
  match 'settings' => 'my_echo#settings', :as => :settings
  
  # SECTION autocomplete
  match ':controller/:action' => '#index', :as => :auto_complete, 
        :constraints => { :action => /auto_complete_for_\S+/ }, :via => get
  
  # Not being logged in
  match 'requires_login' => 'application#flash_info', :as => :requires_login
  
  resources :locales, :controller => 'i18n/locales' do
      resources :translations, :controller => 'i18n/locales'
  end

  match '/translations' => 'i18n/translations#translations', :as => :translations
  match '/asset_translations' => 'i18n/translations#asset_translations', :as => :asset_translations
  match 'translations/filter' => 'i18n/translations#filter', :as => :filter_translations
  
  #SECTION tags
  match 'tags/:action/:id' => 'tags#index', :as => :tags, :id => ''
  
   # SECTION feedback
  resources :feedback, :only => [:new, :create]
  
  # SECTION user signup and login
  resource :user_session, :controller => 'users/user_sessions',
           :path_prefix => '', :only => [:new, :create, :destroy]
  
  resources :profiles, :controller => 'users/profile', :path_prefix => '', :only => [:show, :edit, :update]
  resources :users, :controller => 'users/users', :path_prefix => '' do
    resources :web_addresses, :controller => 'users/web_addresses', :except => [:index]
    resources :spoken_languages, :controller => 'users/spoken_languages', :except => [:index]
    resources :activities, :controller => 'users/activities', :except => [:index]
    resources :memberships, :controller => 'users/memberships', :except => [:index]
  end
  resources :password_resets, :controller => 'users/password_resets', :path_prefix => '', :except => [:destroy]
  resources :reports, :controller => 'users/reports'
 
  
  
  match '/register/:activation_code' => 'users/activations#new', :as => :register
  match '/join' => 'users/users#new', :as => :join
  match '/activate/:id' => 'users/activations#create', :as => :activate
  
  
  
  # SECTION static - contents per controller
  match 'echo/:action' => 'static/echo#show', :as => :echo
  match 'echonomy/:action' => 'static/echonomy#show', :as => :echonomy
  match 'echocracy/:action' => 'static/echocracy#show', :as => :echocracy
  match 'echologic' => 'static/echologic#show', :as => :echologic
  match 'echologic/:action' => 'static/echologic#index', :as => :static
  
  # echo-social routes
  match ':action' => 'static/echosocial#show', :as => :echosocial, :constraints => {:conditions=>{:rails_env => 'development', :host =>'localhost', :port => 3001 }}
  match ':action' => 'static/echosocial#show', :as => :echosocial, :constraints => {:conditions=>{:rails_env => 'staging', :host => "echosocial.echo-test.org" }}
  match ':action' => 'static/echosocial#show', :as => :echosocial, :constraints => {:conditions=>{:rails_env => 'production', :host => "www.echosocial.org" }}
  match ':action' => 'static/echosocial#show', :as => :echosocial, :constraints => {:conditions=>{:rails_env => 'production', :host => "echosocial.org" }}
  match ':action' => 'static/echosocial#show', :as => :echosocial, :constraints => {:conditions=>{:rails_env => 'production', :host => "echosocial-prod-clone.echo-test.org" }}
  
  # SECTION discuss - discussion tree
  scope '/discuss' do 
    resources :questions do
      member do
        get 'new_translation'
        put 'create_translation'
        put 'publish'
        get 'cancel'
        get 'children'
        get 'upload_image'
        get 'reload_image'
      end
      resources :proposals do
        member do
          post 'echo'
          post 'unecho'
          get 'new_translation'
          put 'create_translation'
          get 'incorporate'
          get 'cancel'
          get 'children'
          get 'upload_image'
          get 'reload_image'
        end
        resources :improvement_proposals do
          member do
          post 'echo'
          post 'unecho'
          get 'new_translation'
          put 'create_translation'
          get 'cancel'
          get 'upload_image'
          get 'reload_image'
        end
        end
      end
    end
  end

  # SECTION root
  root :to => 'static/echologic#show'
  
  # SECTION default routes
  match '/:controller(/:action(/:id))'
end