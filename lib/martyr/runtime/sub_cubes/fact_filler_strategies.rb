module Martyr
  module Runtime
    module FactFillerStrategies

      # Instead of every fact object figuring out itself how to extract fact values from the raw data,
      # we calculate a memoized set of strategies in advance.

      def fact_levels_filler_hash
        return @fact_levels_filler_hash if @fact_levels_filler_hash
        hash = {}
        supported_level_definitions.each do |level_definition|
          level_id = level_definition.id
          if has_association_with_level?(level_id)
            level_association = association_from_id(level_id)
            if level_association.degenerate?
              filler = DegenerateLevelAssociationFillerStrategy.new(level_association)
            else
              filler = QueryLevelAssociationFillerStrategy.new(level_association)
            end
          else
            filler = UnassociatedLevelFillerStrategy.new(level_definition)
          end
          hash[level_id] = filler
        end
        @fact_levels_filler_hash = hash
      end

      class DegenerateLevelAssociationFillerStrategy
        def initialize(level_association)
          @fact_alias = level_association.fact_alias
        end

        def value(fact)
          fact.raw.fetch(@fact_alias)
        end
      end

      class QueryLevelAssociationFillerStrategy
        def initialize(level_association)
          @level_association = level_association
        end

        def value(fact)
          fact_key_value = fact.raw.fetch(@level_association.fact_alias)
          FutureFactValue.new(fact, @level_association.level_definition, key_supported: true, fact_key_value: fact_key_value)
        end
      end

      class UnassociatedLevelFillerStrategy
        def initialize(level_definition)
          @level_definition = level_definition
        end

        def value(fact)
          FutureFactValue.new(fact, @level_definition, key_supported: false)
        end
      end

    end
  end
end
