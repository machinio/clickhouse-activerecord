# frozen_string_literal: true

require 'bundler/setup'
require 'pry'
require 'active_record'
require 'clickhouse-activerecord'
require 'active_support/testing/stream'
require 'net/http'

ClickhouseActiverecord.load

FIXTURES_PATH = File.join(File.dirname(__FILE__), 'fixtures')

# Wait for ClickHouse to be ready before running tests.
# This avoids flaky failures when the Docker container is still starting up.
def wait_for_clickhouse!(host:, port:, timeout: 60)
  uri = URI("http://#{host}:#{port}/ping")
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
  waited = 0

  $stdout.write "Waiting for ClickHouse at #{host}:#{port} "
  $stdout.flush

  loop do
    begin
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        puts " ready (#{waited}s)"
        return
      end
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, Net::ReadTimeout
      # ClickHouse not ready yet
    end

    if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      puts " FAILED"
      abort "ClickHouse did not become ready at #{host}:#{port} within #{timeout}s"
    end

    $stdout.write "."
    $stdout.flush
    sleep 1
    waited += 1
  end
end

ch_host = 'localhost'
ch_port = (ENV['CLICKHOUSE_PORT'] || 8123).to_i
wait_for_clickhouse!(host: ch_host, port: ch_port)

# Print ClickHouse server info for CI debugging
begin
  version = Net::HTTP.get(URI("http://#{ch_host}:#{ch_port}/?query=SELECT+version()")).strip
  uptime = Net::HTTP.get(URI("http://#{ch_host}:#{ch_port}/?query=SELECT+uptime()")).strip
  db = ENV['CLICKHOUSE_DATABASE'] || 'test'
  cluster = ENV['CLICKHOUSE_CLUSTER']

  puts "─── ClickHouse ready ───"
  puts "  Version:  #{version}"
  puts "  Uptime:   #{uptime}s"
  puts "  Host:     #{ch_host}:#{ch_port}"
  puts "  Database: #{db}"
  puts "  Cluster:  #{cluster || '(none)'}"
  puts "  Rails:    #{ActiveRecord::VERSION::STRING}"
  puts "  Ruby:     #{RUBY_VERSION}"
  puts "────────────────────────"
rescue => e
  puts "Warning: could not fetch ClickHouse info: #{e.message}"
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.include ActiveSupport::Testing::Stream
  config.raise_errors_for_deprecations!

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each, :migrations) do |example|
    clear_consts
    clear_db

    example.run

    clear_consts
    clear_db
  end
end

ActiveRecord::Base.configurations = HashWithIndifferentAccess.new(
  default: {
    adapter: 'clickhouse',
    host: ch_host,
    port: ch_port,
    database: ENV['CLICKHOUSE_DATABASE'] || 'test',
    username: nil,
    password: nil,
    debug: false,
    cluster_name: ENV['CLICKHOUSE_CLUSTER'],
  }
)

ActiveRecord::Base.establish_connection(:default)

def schema(model)
  model.reset_column_information
  model.columns.each_with_object({}) do |c, h|
    h[c.name] = c
  end
end

def clear_db
  ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table, sync: true) }
rescue ActiveRecord::NoDatabaseError
  # Ignored
end

def clear_consts
  $LOADED_FEATURES.select { |file| file.include? FIXTURES_PATH }.each do |file|
    const = File.basename(file)
                .scan(ActiveRecord::Migration::MigrationFilenameRegexp)[0][1]
                .camelcase
                .safe_constantize

    Object.send(:remove_const, const.to_s) if const
    $LOADED_FEATURES.delete(file)
  end
end
