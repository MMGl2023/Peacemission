# Load the Rails application.
require_relative "application"

require 'yaml'
require 'mixin_class_methods'
require 'core_ext'
require 'make_cached'
require 'active_support'

config = YAML.load_file("#{Rails.root}/config/config.yml") || {}
APP_CONFIG = (config['defaults'] || {}).merge!(config[Rails.env] || {})

ENV["RAILS_ASSET_ID"] = ''

INVITATION_NEEDED = (APP_CONFIG['users'] || {})['invitation_needed']

HOST = APP_CONFIG['host'] || 'rozysk.org'

RAILS_ROOT = Rails.root

# Initialize the Rails application.
Rails.application.initialize!

FILE_HOST = APP_CONFIG['file_host'] || ActionController::Base.asset_host.to_s +  '/s/'

# require 'topics_helper'
# require 'datetime_ext_helper'
# require 'table_ext_helper'
# require 'auto_complete_ext'

