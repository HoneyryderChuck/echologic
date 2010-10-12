# Put this in config/application.rb
require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
#Bundler.require(:default, Rails.env) if defined?(Bundler)


module Echologic
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{RAILS_ROOT}/extras )

    # Specify gems that this application depends on and have them installed with rake gems:install
    # config.gem "bj"
    # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
    # config.gem "sqlite3-ruby", :lib => "sqlite3"
    # config.gem "aws-s3", :lib => "aws/s3"
    
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Skip frameworks you're not going to use. To use Rails without a database,
    # you must remove the Active Record framework.
    # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    config.time_zone = 'UTC'

    # Action Mailer
    config.action_mailer.default_charset = "utf-8"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = :en

    # Session Storage
    config.session_store = :active_record_store

    # add load paths for models in subfolders... this can be extended by further subfolders if neccessary
    config.autoload_paths += %w(statements mailers).collect{|dir|"#{Rails.root.to_s}/app/models/#{dir}"}
    # the same for controllers
    config.autoload_paths += %w(statements).collect{|dir|"#{Rails.root.to_s}/app/controllers/#{dir}"}
    # libs
    config.autoload_paths += %w(activity_tracking_service drafting_service echo_service).collect{|dir|"#{Rails.root.to_s}/lib/#{dir}"}
  end
end