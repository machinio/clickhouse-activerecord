# frozen_string_literal: true

require 'yaml'

module ActiveRecord
  module ConnectionAdapters
    module Clickhouse
      module OID # :nodoc:
        class Map < Type::Value # :nodoc:
          attr_reader :key_type, :value_type

          def initialize(sql_type)
            types = sql_type.match(/Map\((.+),\s?(.+)\)/).captures

            @key_type = cast_type(types.first)
            @value_type = cast_type(types.last)
          end

          def type
            :map
          end

          def cast(value)
            value
          end

          def deserialize(value)
            return value if value.is_a?(Hash)

            YAML.safe_load(value)
          end

          def serialize(value)
            return '{}' if value.nil?

            res = value.map { |k, v| "#{quote(k, key_type)}: #{quote(v, value_type)}" }.join(', ')
            "{#{res}}"
          end

          private

          def cast_type(type)
            return type if type.nil?

            case type
            when /U?Int\d+/
              :integer
            when /DateTime/
              :datetime
            when /Date/
              :date
            when /Array\(.*\)/
              type
            else
              :string
            end
          end

          def quote(value, type)
            case cast_type(type)
            when :string
              "'#{value}'"
            when :integer
              value
            when :datetime, :date
              "'#{value.iso8601}'"
            when /Array\(.*\)/
              byebug
              sub_type = type.match(/Array\((.+)\)/).captures.first
              "[#{value.map { |v| quote(v, sub_type) }.join(', ')}]"
            else
              value
            end
          end
        end
      end
    end
  end
end
