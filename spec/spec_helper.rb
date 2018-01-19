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

DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORTS = %w[12001 12002]
DEFAULT_NODES = DEFAULT_PORTS.map { |port| "#{DEFAULT_HOST}_#{port}" }
SHELL_LOG_PATH = 'roma_spec_outputs.log'

def start_roma(host: DEFAULT_HOST, ports: DEFAULT_PORTS)
  nodes = ports.map { |port| "#{host}_#{port}" }

  nodes.each do |node|
    FileUtils.rm(Dir.glob(["#{node}.log*", "#{node}.route*"]))
  end

  system("mkroute #{nodes.join(' ')} --replication_in_host >> #{SHELL_LOG_PATH} 2>&1")

  ports.each do |port|
    system("romad #{host} -p #{port} -d --replication_in_host --disabled_cmd_protect >> #{SHELL_LOG_PATH} 2>&1")
  end
end

def stop_roma(host: DEFAULT_HOST, port: DEFAULT_PORTS[0])
  sock = TCPSocket.new(host, port)
  sock.write("shutdown\r\n")
  sock.gets
  sock.write "yes\r\n"
  sock.gets
  sock.close
  Roma::Client::ConPool.instance.close_all
rescue => e
  puts "#{e}: #{ $ERROR_POSITION}\n  " + e.backtrace.join("\n  ")
end
