module ActiveRecord
  module ConnectionAdapters
    module Clickhouse
      class Column < ActiveRecord::ConnectionAdapters::Column

        attr_reader :codec

        def initialize(*, codec: nil, **)
          super
          @codec = codec
        end

        def key_type
          return nil unless type == :map

          cast_type(map_types.first)
        end

        def value_type
          return nil unless type == :map

          cast_type(map_types.last)
        end

        private

        def map_types
          sql_type_metadata.sql_type.match(/Map\((.+)\,\s?(.+)\)/).captures
        end

        def cast_type(type)
          return type if type.nil?

          case type
          when /U?Int\d+/
            :integer
          when /DateTime/
            :datetime
          when /Date/
            :date
          when /Array/
            type
          else
            :string
          end
        end

        private

        def deduplicated
          self
        end
      end
    end
  end
end
