# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
# For using link_to and url_for in ActionMailer, hostname has to be given.
config.action_mailer.default_url_options = { :host => 'staging.echo-test.org' }

# Hosts
ECHOLOGIC_HOST = 'echologic.echo-test.org'
ECHOSOCIAL_HOST = 'echosocial.echo-test.org'

# Feedback recipient
FEEDBACK_RECIPIENT = 'laszlo.papp@echologic.org'


config.activity_tracking.charges = 1
config.activity_tracking.period = 10.minutes 