module Martyr
  class MetricIdStandardizer
    include Martyr::Translations

    def initialize(cube_name = nil, raise_if_not_ok: false)
      @cube_name = cube_name
      @raise_if_not_ok = raise_if_not_ok
    end

    def standardize(object)
      if object.is_a?(String) or object.is_a?(Symbol)
        standardize_id(object)
      elsif object.is_a?(Array)
        standardize_arr(object)
      elsif object.is_a?(Hash)
        standardize_hash(object)
      else
        raise Internal::Error.new("Does not know how to standardize #{object.inspect}")
      end
    end

    def standardize_id(id)
      with_standard_id(id) do |dimension_or_cube_or_metric, level_or_metric|
        level_or_metric ? id : add_cube_name_to(dimension_or_cube_or_metric)
      end
    end

    def standardize_arr(arr)
      arr.map{|id| standardize_id(id)}
    end

    def standardize_hash(hash)
      arr = hash.map do |key, value|
        [standardize_id(key), value]
      end
      Hash[arr]
    end

    private

    def add_cube_name_to(id)
      raise Query::Error.new("Invalid metric #{id}: must be preceded with cube name") if @raise_if_not_ok
      @cube_name.nil? ? id : "#{@cube_name}.#{id}"
    end

  end
end
