module Martyr
  module Registrable
    def register(object)
      send(:[]=, object.name.to_s, object)
    end

    def find_or_error(name)
      send(:[], name.to_s) || raise(Runtime::Error.new "Could not find `#{name}`")
    end
  end
end