module Martyr
  module Translations

    def with_standard_id(id)
      x, y = id_components(id)
      y.nil? ? yield(id.to_s) : yield(x, y)
    end

    def id_components(id)
      id_s = id.to_s
      id_s.split('.')
    end

    def first_element_from_id(id)
      id.to_s.include?('.') ? id.to_s.split('.').first : id.to_s
    end

    # @param id [String]
    # @option fallback [Boolean] if true, will return the id if only one element exists in the id
    def second_element_from_id(id, fallback: false)
      if id.to_s.include?('.')
        id.to_s.split('.').last
      else
        fallback ? id.to_s : nil
      end
    end

    def to_id(object)
      return object if object.is_a?(String)
      object.id
    end

  end
end
