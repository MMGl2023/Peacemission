# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'yaml'
require 'mixin_class_methods'
require 'core_ext'
require 'make_cached'

config = YAML.load_file( "#{RAILS_ROOT}/config/config.yml" ) || {}
APP_CONFIG = (config['defaults']||{}).merge!( config[RAILS_ENV] || {} )

ENV["RAILS_ASSET_ID"] = ''

INVITATION_NEEDED = (APP_CONFIG['users']||{})['invitation_needed']

HOST = APP_CONFIG['host'] || 'rozysk.org'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W(
      #{RAILS_ROOT}/app/sweepers
  )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_mmgl_session',
    :secret      => '0cb13c80b224771c03d1b1d567924177682af3f8f6c4327b7d3614df7cdb200c3d929e29608f7c34bf1836e0593ccdd2ccb64ac99cc765ca7c43f16f6bf8eb8a'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')

  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :user_observer, :invitation_observer

  config.action_controller.perform_caching = true

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  config.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache/"
  # Only for production
  # config.action_controller.asset_host = "http://static.rozysk.org"
end


FILE_HOST = APP_CONFIG['file_host'] || ActionController::Base.asset_host.to_s +  '/s/'

require 'topics_helper'
require 'datetime_ext_helper'
require 'table_ext_helper'
require 'auto_complete_ext'

