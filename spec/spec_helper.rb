# frozen_string_literal: true

require 'rspec'
require 'simplecov'

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__),
                                              '..', 'lib'))
Dir[File.dirname(__FILE__) + '/supports/**/*.rb'].each { |f| require f }

require 'roma-client'

SimpleCov.start do
  add_filter '/vendor/'
end

RSpec.configure do |config|
  config.mock_with :rr
end
