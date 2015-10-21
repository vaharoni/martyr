module Martyr
  module Runtime
    class ScopeableSliceData

      # Scoping applies on #keys, #values, #to_hash.

      delegate :[], :[]=, :select!, :reject!, to: :@data
      delegate :keys, :values, to: :to_hash

      def initialize(data = {})
        @data = data
      end

      # @return [ScopeableDataSliceData] new instance scoped to cube
      def scope(sub_cube)
        dup.scope!(sub_cube)
      end

      def scope!(sub_cube)
        @sub_cube = sub_cube
        self
      end

      def to_hash
        scoped_data
      end

      def select(&block)
        obj = data_dup
        obj.select!(&block)
        obj
      end

      def reject(&block)
        obj = data_dup
        obj.reject!(&block)
        obj
      end

      private

      def scoped_data
        return @data unless @sub_cube
        return @scoped_data if @scoped_data

        cube_name = @sub_cube.cube_name
        metrics_hash = @data.select do |_key, object|
          object.respond_to?(:cube_name) and object.cube_name == cube_name
        end

        # We go through the cube so that ScopeableSliceData is the same regardless if we're dealing with data slice
        # (can always perform WHERE clause) or memory slice (can only be applied on levels in the grain). The downside
        # is that for memory slices the scoped_data may contain levels that cannot be sliced
        supported_level_ids = @sub_cube.cube.supported_level_ids
        supported_dimension_names = @sub_cube.dimension_definitions.keys
        dimensions_arr = @data.select do |key, object|
          !object.respond_to?(:cube_name) and
            supported_dimension_names.include?(key) and
            (object.keys - (object.keys - supported_level_ids)).present?
        end.map do |key, object|
          [key, object.scope(supported_level_ids)]
        end

        @scoped_data = metrics_hash.merge! Hash[dimensions_arr]
      end

      def data_dup
        self.class.new(@data.dup)
      end

    end
  end
end
