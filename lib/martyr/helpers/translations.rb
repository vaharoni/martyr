module Martyr
  module Translations

    def with_standard_id(id)
      if id.to_s.include?('.')
        x, y = id.to_s.split('.')
        yield x, y
      else
        yield id.to_s
      end
    end

    def first_element_from_id(id)
      id.to_s.include?('.') ? id.to_s.split('.').first : id.to_s
    end

    def second_element_from_id(id)
      id.to_s.include?('.') ? id.to_s.split('.').last : id.to_s
    end

    def to_id(object)
      return object if object.is_a?(String)
      object.id
    end

  end
end
