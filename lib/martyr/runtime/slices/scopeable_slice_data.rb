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
      def scope(cube_name)
        dup.scope!(cube_name)
      end

      def scope!(cube_name)
        @cube_name = cube_name
        self
      end

      def to_hash
        return @data unless @cube_name
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
        @data.select{|x| x.respond_to?(:cube_name) ? x.cube_name == @cube_name : true}
      end

      def data_dup
        self.class.new(@data.dup)
      end

    end
  end
end
