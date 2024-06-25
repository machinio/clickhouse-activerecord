module ActiveRecord
  module ConnectionAdapters
    module Clickhouse
      module Quoting
        QUOTED_COLUMN_NAMES = Concurrent::Map.new

        # Quotes column names for use in SQL queries.
        def quote_column_name(name) # :nodoc:
          QUOTED_COLUMN_NAMES[name] ||= name.to_s['.'] ? "`#{name}`" : name.to_s
        end
      end
    end
  end
end
