module Martyr
  class Error < StandardError
  end

  module Schema
    class Error < ::Martyr::Error
    end
  end

  module Query
    class Error < ::Martyr::Error
    end
  end

end