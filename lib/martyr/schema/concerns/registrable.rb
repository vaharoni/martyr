module Martyr
  module Schema
    module Registrable
      def register(object)
        send(:[]=, object.name.to_s, object)
      end
    end
  end
end
