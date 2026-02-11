module CoreExtensions
  module Arel
    module SelectManager

      def final!
        @ctx.final = true
        self
      end

      # @param [Hash] values
      def settings(values)
        @ast.settings = ::Arel::Nodes::Settings.new(values)
        self
      end

      def using(*exprs)
        @ctx.source.right.last.right = ::Arel::Nodes::Using.new(::Arel.sql(exprs.join(',')))
        self
      end

      def limit_by(*exprs)
        @ast.limit_by = ::Arel::Nodes::LimitBy.new(*exprs)
        self
      end
    end
  end
end
