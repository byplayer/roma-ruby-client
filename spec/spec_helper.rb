# frozen_string_literal: true

if ENV['CI']
  require 'coveralls'

  Coveralls.wear!
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'rspec'
require 'roma/romad'

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__),
                                              '..', 'lib'))

Dir[File.dirname(__FILE__) + '/supports/**/*.rb'].each { |f| require f }

require 'roma-client'

DEFAULT_HOST = 'localhost'
DEFAULT_PORTS = %w[11311 11411]
DEFAULT_NODES = DEFAULT_PORTS.map { |port| "#{DEFAULT_HOST}_#{port}" }
SHELL_LOG_PATH = 'roma_spec_outputs.log'
