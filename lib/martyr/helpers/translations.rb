module Martyr
  module Translations

    def with_standard_id(id)
      id_s = id.to_s
      x, y = id_s.split('.')
      y.nil? ? yield(id_s) : yield(x, y)
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
