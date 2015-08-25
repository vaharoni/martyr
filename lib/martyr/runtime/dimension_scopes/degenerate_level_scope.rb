module Martyr
  module Runtime
    class DegenerateLevelScope < BaseLevelScope

      delegate :query_level_with_finder, :query_level_without_finder, :query_level_key, to: :level

      def slice_with(values)
        query_level_below.send(:decorate_scope) do |scope|
          query_level_with_finder.call(scope, values)
        end
        load_query_level_slice
      end

      def slice_without(values)
        query_level_below.send(:decorate_scope) do |scope|
          query_level_without_finder.call(scope, values)
        end
        load_query_level_slice
      end

      def loaded?
        query_level_below.loaded?
      end

      def all
        cache.keys
      end
      alias_method :keys, :all

      # Useful when the fact is attempting to resolve Degenerate 1 value:
      #   Degenerate 1
      #         Degenerate 2    ----    Cube
      #               Query 3
      #
      def recursive_value_lookup(degenerate_value, level:)
        return degenerate_value if name == level.name
        query_level_below.recursive_value_lookup(cache[degenerate_value], level: level)
      end

      private

      def load_query_level_slice
        query_level_below.send(:execute_query)
      end

      # The cache stored is basically one representative of the query level for each degenerate value.
      # Assuming the hierarchy is strict, i.e. the state parent of "San Francisco" is always "California", we are able
      # to infer correctly the hierarchy
      def cache
        @cache ||= query_level_below.keys.index_by{|x| x.send(query_level_key)}
      end

    end
  end
end