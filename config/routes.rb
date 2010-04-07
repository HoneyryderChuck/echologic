#
# Rails routing guide: http://guides.rubyonrails.org/routing.html
#
ActionController::Routing::Routes.draw do |map|

  # routing-filter plugin for wrapping :locale around urls and paths.
  map.filter :locale

  

  # SECTION main parts of echologic
  map.act     '/act/roadmap',     :controller => :act,     :action => :roadmap
  map.discuss '/discuss', :controller => :discuss, :action => :index
  map.discuss_roadmap '/discuss/roadmap', :controller => :discuss, :action => :roadmap  
  map.discuss_search '/discuss/search', :controller => :questions, :action => :category
  map.question_tags '/discuss/:id', :controller => :questions, :action => :category, :conditions => {:id => /\w+/ }
  
  map.my_echo '/my_echo/roadmap', :controller => :my_echo, :action => :roadmap

  map.resource :connect, :controller => 'connect', :only => [:show]
  map.resource :admin,   :controller => 'admin',   :only => [:show]

  # SECTION my echo routing
  map.my_profile 'my_profile', :controller => 'my_echo', :action => 'profile'

  map.resources :profiles, :controller => 'users/profile', :path_prefix => '', :only => [:show, :edit, :update]
  map.profile_details '/profiles/:id/details', :controller => 'users/profile', :action => 'details'

  map.welcome   'welcome', :controller => 'my_echo', :action => 'welcome'

  # SECTION autocomplete
  map.auto_complete ':controller/:action',
    :requirements => { :action => /auto_complete_for_\S+/ },
    :conditions => { :method => :get }

  # SECTION i18n
  map.resources :locales, :controller => 'i18n/locales' do |locale|
    locale.resources :translations, :controller => 'i18n/translations'
  end
  map.translations '/translations', :controller => 'i18n/translations', :action => 'translations'
  map.asset_translations '/asset_translations', :controller => 'i18n/translations', :action => 'asset_translations'
  map.filter_translations 'translations/filter', :controller => 'i18n/translations', :action => 'filter'

  # SECTION feedback
  map.resources :feedback, :only => [:new, :create]

  # SECTION user signup and login
  map.resource  :user_session, :controller => 'users/user_sessions',
                :path_prefix => '', :only => [:new, :create, :destroy]

  map.resources :users, :controller => 'users/users', :path_prefix => '' do |user|
    user.resources :web_profiles, :controller => 'users/web_profiles', :except => [:index]
    user.resources :activities,   :controller => 'users/activities',   :except => [:index]
    user.resources :memberships,  :controller => 'users/memberships',  :except => [:index]
  end

  map.resources :password_resets, :controller => 'users/password_resets',
                :path_prefix => '', :except => [:destroy]

  map.register  '/register/:activation_code', :controller => 'users/activations', :action => 'new'
  map.join      '/join',                      :controller => 'users/users',       :action => 'new'
  map.activate  '/activate/:id',              :controller => 'users/activations', :action => 'create'

  map.resources :reports, :controller => 'users/reports'


  # SECTION static - contents per controller
  map.echo      'echo/:action',      :controller => 'static/echo',      :action => 'show'
  map.echonomy  'echonomy/:action',  :controller => 'static/echonomy',  :action => 'show'
  map.echocracy 'echocracy/:action', :controller => 'static/echocracy', :action => 'show'  
  map.echologic 'echologic',         :controller => 'static/echologic', :action => 'show'  
  map.static    'echologic/:action', :controller => 'static/echologic'
  
   
  map.echosocial ':action',:controller => 'static/echosocial',:action => 'show', :conditions=>{:rails_env => 'development', :host =>'localhost', :port => 3001 } 
  map.echosocial ':action',:controller => 'static/echosocial',:action => 'show', :conditions=>{:rails_env => 'staging', :domain => "echosocial.echo-test.org" }
  map.echosocial ':action',:controller => 'static/echosocial',:action => 'show', :conditions=>{:rails_env => 'production', :domain => "echosocial.org" }

  # SECTION discuss - discussion tree
  map.resources :questions, :as => 'discuss/questions' do |question|
    question.resources :proposals, :member => [:echo, :unecho] do |proposal|
      proposal.resources :improvement_proposals, :member => [:echo, :unecho] do |improvement_proposal|
      end
    end
  end


  # SECTION root
  map.root :controller => 'static/echologic', :action => 'show'

  # SECTION default routes
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
