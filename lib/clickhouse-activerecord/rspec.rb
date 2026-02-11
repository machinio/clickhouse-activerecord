# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    original_db_config = ActiveRecord::Base.connection_db_config
    ActiveRecord::Base.configurations.configurations.select { |x| x.env_name == Rails.env && x.adapter == 'clickhouse' }.each do |db_config|
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::Base.connection.truncate_tables(*ActiveRecord::Base.connection.tables)
    end
  ensure
    ActiveRecord::Base.establish_connection(original_db_config)
  end
end
