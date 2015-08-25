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
      id.to_s.include?('.') ? id.to_s.split('.').first : id
    end

  end
end