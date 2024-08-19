# frozen_string_literal: true

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
            if value.is_a?(::Hash)
              value.map { |k, item| [k.to_s, deserialize(item)] }.to_h
            else
              return value if value.nil?
              case @value_type
                when :integer
                  value.to_i
                when :datetime
                  ::DateTime.parse(value)
                when :date
                  ::Date.parse(value)
              else
                super
              end
            end
          end

          def serialize(value)
            if value.is_a?(::Hash)
              value.map { |k, item| [k.to_s, serialize(item)] }.to_h
            else
              return value if value.nil?
              case @value_type
                when :integer
                  value.to_i
                when :datetime
                  DateTime.new.serialize(value)
                when :date
                  Date.new.serialize(value)
                when :string
                  value.to_s
              else
                super
              end
            end
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
