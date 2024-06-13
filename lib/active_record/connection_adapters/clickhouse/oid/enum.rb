# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Clickhouse
      module OID # :nodoc:
        class Enum < Type::Value # :nodoc:

          def initialize(sql_type)
            @subtype = case sql_type
                       when /Enum8/
                         :enum8
                       when /Enum16/
                         :enum16
            end
          end

          def type
            @subtype
          end
        end
      end
    end
  end
end
