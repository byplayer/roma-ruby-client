# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'rubygems/package_task'
require 'rspec/core'
require 'rspec/core/rake_task'

begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
end

RDOC_OPTIONS = %w[ --line-numbers
                   --inline-source
                   --main README.md
                   -c UTF-8].freeze

# gem tasks
PKG_FILES = FileList[
  '[A-Z]*',
  'bin/**/*',
  'lib/**/*.rb',
  'test/**/*.rb',
  'spec/**/*.rb',
  'doc/**/*',
  'examples/**/*']

require File.expand_path(File.join('lib', 'roma', 'client', 'version'),
                         File.dirname(__FILE__))

VER_NUM = Roma::Client::VERSION::STRING

CURRENT_VERSION =
  if VER_NUM =~ /([0-9.]+)$/
    Regexp.last_match[1]
  else
    '0.0.0'
  end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = ''
end
task default: :spec

SPEC = Gem::Specification.new do |s|
  s.authors = ['Muga Nishizawa', 'Junji Torii']
  s.name = 'roma-client'
  s.version = CURRENT_VERSION
  s.summary = 'ROMA client library'
  s.description = 'ROMA client library'
  s.files = PKG_FILES.to_a

  s.required_ruby_version = '>= 2.0.0'

  s.require_path = 'lib'

  s.has_rdoc = true
  s.rdoc_options.concat RDOC_OPTIONS
  s.extra_rdoc_files = %w[README CHANGELOG]
end

Gem::PackageTask.new(SPEC) do |pkg|
end

Rake::RDocTask.new('doc') do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = 'ROMA documents'
  rdoc.options.concat RDOC_OPTIONS
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include("README.md")
  rdoc.rdoc_files.include("CHANGELOG.md")
end
