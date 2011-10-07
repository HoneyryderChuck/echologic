
# Edit at your own peril - it's recommended to regenerate this file
# in the future when you upgrade to a newer version of Cucumber.

# IMPORTANT: Setting config.cache_classes to false is known to
# break Cucumber's use_transactional_fixtures method.
# For more information see https://rspec.lighthouseapp.com/projects/16211/tickets/165
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false


# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test
config.action_mailer.default_url_options = { :host => 'localhost:3000' }

# Testing gems
config.gem 'flexmock', :version => '0.9.0'
config.gem 'shoulda', :version => '2.11.3'
config.gem 'test-unit', :lib => 'test/unit', :version => '2.0.9'

config.gem "cucumber", :lib => false, :version => "0.8.3"
config.gem "cucumber-rails", :lib => false, :version => "0.3.2"
config.gem 'database_cleaner', :lib => false, :version => '0.4.3'
config.gem 'rspec', :lib => false, :version => '1.3.2'
config.gem 'rspec-rails', :lib => false, :version => '1.3.4'
config.gem 'webrat', :lib => false, :version => '0.7.3'

# Number of children statements shown
TOP_CHILDREN = 7
MORE_CHILDREN = 7
TOP_ALTERNATIVES = 7
