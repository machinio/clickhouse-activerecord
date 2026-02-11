module CoreExtensions
  module ActiveRecord
    module Relation

      def self.prepended(base)
        base::VALID_UNSCOPING_VALUES << :final << :settings
      end

      # Define settings in the SETTINGS clause of the SELECT query. The setting value is applied only to that query and is reset to the default or previous value after the query is executed.
      # For example:
      #
      #   users = User.settings(optimize_read_in_order: 1, cast_keep_nullable: 1).where(name: 'John')
      #   # SELECT users.* FROM users WHERE users.name = 'John' SETTINGS optimize_read_in_order = 1, cast_keep_nullable = 1
      #
      # An <tt>ActiveRecord::ActiveRecordError</tt> will be raised if database not ClickHouse.
      # @param [Hash] opts
      def settings(**opts)
        spawn.settings!(**opts)
      end

      # @param [Hash] opts
      def settings!(**opts)
        check_command!('SETTINGS')
        self.settings_values = settings_values.merge opts
        self
      end

      def settings_values
        @values.fetch(:settings, ::ActiveRecord::QueryMethods::FROZEN_EMPTY_HASH)
      end

      def settings_values=(value)
        if ::ActiveRecord::version >= Gem::Version.new('7.2')
          assert_modifiable!
        else
          assert_mutability!
        end
        @values[:settings] = value
      end

      # When FINAL is specified, ClickHouse fully merges the data before returning the result and thus performs all data transformations that happen during merges for the given table engine.
      # For example:
      #
      #   users = User.final.all
      #   # SELECT users.* FROM users FINAL
      #
      # An <tt>ActiveRecord::ActiveRecordError</tt> will be raised if database not ClickHouse.
      #
      # @param [Boolean] final
      def final(final = true)
        spawn.final!(final)
      end

      # @param [Boolean] final
      def final!(final = true)
        check_command!('FINAL')
        self.final_value = final
        self
      end

      def final_value=(value)
        if ::ActiveRecord::version >= Gem::Version.new('7.2')
          assert_modifiable!
        else
          assert_mutability!
        end
        @values[:final] = value
      end

      def final_value
        @values.fetch(:final, nil)
      end

      # The USING clause specifies one or more columns to join, which establishes the equality of these columns. For example:
      #
      #   users = User.joins(:joins).using(:event_name, :date)
      #   # SELECT users.* FROM users INNER JOIN joins USING event_name,date
      #
      # An <tt>ActiveRecord::ActiveRecordError</tt> will be raised if database not ClickHouse.
      # @param [Array] opts
      def using(*opts)
        spawn.using!(*opts)
      end

      # @param [Array] opts
      def using!(*opts)
        @values[:using] = opts
        self
      end

      private

      def check_command!(cmd)
        raise ::ActiveRecord::ActiveRecordError, cmd + ' is a ClickHouse specific query clause' unless connection.is_a?(::ActiveRecord::ConnectionAdapters::ClickhouseAdapter)
      end

      def build_arel(connection_or_aliases = nil, aliases = nil)
        requirement = Gem::Requirement.new('>= 7.2', '< 8.1')

        if requirement.satisfied_by?(::ActiveRecord::version)
          arel = super
        else
          arel = super(connection_or_aliases)
        end

        arel.final! if final_value
        arel.settings(settings_values) unless settings_values.empty?
        arel.using(@values[:using]) if @values[:using].present?

        arel
      end
    end
  end
end
