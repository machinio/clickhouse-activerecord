module ActiveRecord
  module ConnectionAdapters
    module Clickhouse
      module Quoting
        extend ActiveSupport::Concern

        module ClassMethods # :nodoc:
          QUOTED_COLUMN_NAMES = Concurrent::Map.new
          # Quotes column names for use in SQL queries.
          def quote_column_name(name)
            QUOTED_COLUMN_NAMES[name] ||= name.to_s['.'] ? "`#{name}`" : name.to_s
          end

          def quote_table_name(name)
            name
          end
        end
      end
    end
  end
end
