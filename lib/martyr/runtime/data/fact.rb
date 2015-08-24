module Martyr
  module Runtime
    class Fact < HashWithIndifferentAccess
      include Martyr::LevelComparator


    end
  end
end