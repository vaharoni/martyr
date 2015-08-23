module Martyr
  module Runtime
    class DegenerateLevelScope < BaseLevelScope

      delegate :query_level_with_finder, :query_level_without_finder, :query_level_key, to: :level

      def query_level_below
        @_query_level_below ||= collection.query_level_below(name)
      end

      def slice_with(values)
        query_level_below.send(:decorate_scope) do |scope|
          query_level_with_finder.call(scope, values)
        end
        run
      end

      def slice_without(values)
        query_level_below.send(:decorate_scope) do |scope|
          query_level_without_finder.call(scope, values)
        end
        run
      end

      def all
        @cache
      end

      alias_method :keys, :all

      def run
        query_level_below.send(:run)
        @loaded = true
        @cache = query_level_below.all.map{|x| x.send(query_level_key)}
      end

    end
  end
end