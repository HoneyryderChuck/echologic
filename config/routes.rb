#
# Rails routing guide: http://guides.rubyonrails.org/routing.html
#
ActionController::Routing::Routes.draw do |map|

  # Routing-filter plugin for wrapping :locale around URLs and paths.
  map.filter :locale
  map.filter :mode


  ##################
  # DISCUSS routes #
  ##################

  # Submenus
  map.discuss_search '/discuss/search', :controller => :statements, :action => :category
  map.discuss_featured '/discuss/featured', :controller => :discuss, :action => :index
  map.my_questions '/discuss/my_questions', :controller => :statements, :action => :my_questions
  map.discuss_roadmap '/discuss/roadmap', :controller => :discuss, :action => :roadmap

  # Statements
  map.resources :statement_nodes,
                :controller => :statements,
                :member => [:echo, :unecho, :new_translation, :create_translation, :cancel, :social_widget,
                            :children, :more, :authors, :publish, :incorporate, :ancestors, :descendants, :share,
                            :link_statement, :link_statement_node],
                :path_names => { :new => ':id/new/:type',
                                 :more => 'more/:type',
                                 :children => 'children/:type',
                                 :descendants => 'descendants/:type/',
                                 :new_translation => 'translation/:current_document_id',
                                 :incorporate => 'incorporate/:approved_ip',
                                 :link_statement_node => 'link_statement_node/:type',
                                 :edit => 'edit/:current_document_id'},
                :as => 'statement'

  # Create and update statements
  map.resources :questions, :controller => :statements, :only => [:create, :update]
  map.resources :proposals, :controller => :statements, :only => [:create, :update]
  map.resources :improvements, :controller => :statements, :only => [:create, :update]
  map.resources :pro_arguments, :controller => :statements, :only => [:create, :update]
  map.resources :contra_arguments, :controller => :statements, :only => [:create, :update]
  map.resources :background_infos, :controller => :statements, :only => [:create, :update]
  map.resources :follow_up_questions, :controller => :statements, :only => [:create, :update]

  # Statement images
  map.resources :statement_images,
                :member => [:load, :reload], :only => [:new, :create, :edit, :update],
                :path_names => {:edit => 'statement/:node_id/edit',
                                :new => 'new/:type'}, :as => 'image'
  #Statement images load on form
  map.load_statement_image 'image/load/:type/:id', :controller => :statement_images, :action => :load

  # Add statement teasers
  map.add_teaser  'statement/:id/add/:type', :controller => :statements, :action => :add

  # Question routes
  map.add_question_teaser 'statement/add/question',
                          :controller => :statements,
                          :action => :add,
                          :type => :question
  map.new_question 'statement/new/question',
                   :controller => :statements,
                   :action => :new,
                   :type => :question
  map.question_descendants 'statement/descendants/question/',
                           :controller => :statements,
                           :action => :descendants,
                           :type => :question

  # Linking statements
  map.connect 'statement/link_statement/:id',
              :controller => :statements,
              :action => :link_statement

  # Publish statement
  map.publish_statement 'statement/:id/publish/:in',
                        :controller => :statements,
                        :action => :publish,
                        :method => :put

  # Redirecting old discuss paths
  map.connect 'discuss/questions/:question_id/proposals/:id',
              :controller => :statements,
              :action => :redirect_to_statement
  map.connect 'discuss/questions/:question_id/proposals/:proposal_id/improvement_proposals/:id',
              :controller => :statements,
              :action => :redirect_to_statement


  ##################
  # CONNECT routes #
  ##################

  # Submenus
  map.connect_search '/connect/search', :controller => :connect, :action => :show
  map.connect_roadmap '/connect/roadmap', :controller => :connect, :action => :roadmap

  # Profile
  map.resources :profiles, :controller => 'users/profiles',
                :path_prefix => '',
                :only => [:show, :edit, :update]
  map.profile_details '/profiles/:id/details',
                      :controller => 'users/profiles',
                      :action => 'details'
  map.new_user_mail '/profiles/:id/new_mail',
                    :controller => 'users/profiles',
                    :action => :new_mail
  map.send_user_mail '/profiles/:id/send_mail',
                     :controller => 'users/profiles',
                     :action => :send_mail,
                     :method => :post
  map.resources :reports,
                :controller => 'users/reports'


  ##############
  # ACT routes #
  ##############

  map.act_roadmap '/act/roadmap', :controller => :act, :action => :roadmap


  ##################
  # MY ECHO routes #
  ##################

  # Submenus
  map.my_profile 'my_profile',
                 :controller => 'my_echo',
                 :action => 'profile'
  map.settings 'settings',
               :controller => 'my_echo',
               :action => 'settings'
  map.my_echo_roadmap '/my_echo/roadmap',
              :controller => :my_echo,
              :action => :roadmap
  map.welcome 'welcome',
              :controller => 'my_echo',
              :action => 'welcome'

  # My Profile
  map.resources :users, :controller => 'users/users', :path_prefix => '' do |user|
    user.resources :web_addresses, :controller => 'users/web_addresses', :except => [:index]
    user.resources :spoken_languages, :controller => 'users/spoken_languages', :except => [:index]
    user.resources :activities,   :controller => 'users/activities',   :except => [:index]
    user.resources :memberships,  :controller => 'users/memberships',  :except => [:index]
  end


  ########################
  # Model related routes #
  ########################

  # Tags
  map.tags 'tags/:action/:id',
           :controller => :tags,
           :action => :index,
           :id => ''


  ###########################
  # Workflow related routes #
  ###########################

  # Login
  map.resources :user_sessions,
                :controller => 'users/user_sessions',
                :path_prefix => ''
  map.resources :password_resets,
                :controller => 'users/password_resets',
                :path_prefix => '',
                :except => [:destroy]

  # Register
  map.register   '/register/:activation_code', :controller => 'users/activations', :action => 'basic_profile'
  map.activate   '/activate/:activation_code', :controller => 'users/activations', :action => 'activate', :method => :post
  map.signin     '/signin',                    :controller => 'users/user_sessions', :action => 'new'
  map.signup     '/signup',                    :controller => 'users/users', :action => 'new'
  map.signout    '/signout',                   :controller => 'users/user_sessions', :action => 'destroy'
  map.pending_action '/pending_action/:token', :controller => 'users/activations', :action => 'activate_email'
  map.setup_basic_profile '/setup_basic_profile/:activation_code',
                          :controller => 'users/users',
                          :action => 'setup_basic_profile'

  # Social accounts
  map.signin_remote '/signin_remote',
                    :controller => 'users/user_sessions',
                    :action => 'create_social',
                    :method => :post
  map.signup_remote '/signup_remote',
                    :controller => 'users/users',
                    :action => 'create_social',
                    :method => :post
  map.add_remote '/add_remote/',
                 :controller => 'users/users',
                 :action => 'add_social',
                 :method => :post
  map.remove_remote '/remove_remote/:provider',
                    :controller => 'users/users',
                    :action => 'remove_social',
                    :method => :put

  # Feedback
  map.resources :feedback,
                :only => [:new, :create]


  ##################
  # Utility routes #
  ##################

  # Auto-completion for values
  map.auto_complete ':controller/:action',
    :requirements => { :action => /auto_complete_for_\S+/ },
    :conditions => { :method => :get }
  map.connect 'statements/auto_complete_for_statement_title', # TODO: WHY DOES THE PREVIOUS ROUTE DOES NOT WORK???
              :controller => :statements,
              :action => :auto_complete_for_statement_title

  # Login is required
  map.requires_login 'requires_login',
                     :controller => 'application',
                     :action => 'flash_info'

  # Popup redirection
  map.redirect_from_popup '/redirect_from_popup',
                          :controller => 'application',
                          :action => 'redirect_from_popup',
                          :method => :post


  ###############
  # HOME routes #
  ###############

  map.echo      'echo/:action',      :controller => 'static/echo',      :action => 'show'
  map.echonomy  'echonomy/:action',  :controller => 'static/echonomy',  :action => 'show'
  map.echocracy 'echocracy/:action', :controller => 'static/echocracy', :action => 'show'
  map.echologic 'echologic',         :controller => 'static/echologic', :action => 'show'
  map.static    'echologic/:action', :controller => 'static/echologic'


  ################
  # ADMIN routes #
  ################

  map.resource :admin, :controller => 'admin', :only => [:show]

  # Admin functions
  map.resources :newsletters
  map.resources :about_items, :controller => 'about_items', :active_scaffold => true

  # DB localization (NOT used)
  map.resources :locales, :controller => 'i18n/locales' do |locale|
    locale.resources :translations, :controller => 'i18n/translations'
  end
  map.translations '/translations', :controller => 'i18n/translations', :action => 'translations'
  map.asset_translations '/asset_translations', :controller => 'i18n/translations', :action => 'asset_translations'
  map.filter_translations 'translations/filter', :controller => 'i18n/translations', :action => 'filter'


  #####################
  # Public API routes #
  #####################

  # oEmbed API
  map.oembed '/api/oembed', :controller => :api, :action => :oembed
  map.oembed '/api/oembed.:format', :controller => :api, :action => :oembed


  ##################
  # Unmatched URLs #
  ##################

  # Default routes
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  # Root and application's home URLs
  map.root :controller => 'static/echologic',
           :action => 'show'
  map.app_home '/discuss/search', :controller => :statements, :action => :category


  # Shortcut URLs
  map.shortcut ':shortcut',
               :controller => :application,
               :action => :shortcut

end
