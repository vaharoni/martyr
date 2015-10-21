module Martyr
  module Runtime
    class VirtualElementsBuilder

      def initialize(unsliced_level_ids_in_grain:)
        @entries = []
        @unsliced_level_ids_in_grain = unsliced_level_ids_in_grain
        @lookups_by_level_id = {}
      end

      # @param elements [Array<Element>]
      # @param sliced [Boolean] true if cube has at least one sliced level or metric
      def add(elements, sliced:)
        return unless elements.present?
        @entries << ElementsFromSubCube.new(elements, sliced, @lookups_by_level_id, @unsliced_level_ids_in_grain)
      end

      # Let's take 3 cubes:
      #
      #       Schools:
      #         Country
      #         City
      #         Name
      #
      #       Courses:
      #         Topic
      #         Course name
      #
      #       Students:
      #         Country
      #         City
      #         Name
      #
      # Cube 1 - city budgets for schools
      #   (D) schools.country
      #   (D) schools.city
      #   (M) budget
      #
      # Cube 2 - Student performance
      #   (D) schools.country
      #   (D) schools.city
      #   (D) schools.name
      #   (D) students.country
      #   (D) students.city
      #   (D) students.name
      #   (D) courses.topic
      #   (D) courses.name
      #   (M) grade
      #
      # Cube 3 - International statistics
      #   (D) courses.topic
      #   (M) importance_factor
      #
      # Cube 4 = National statistics
      #   (D) schools.country
      #   (D) courses.topic
      #   (M) national_importance_factor
      #
      # = Reports
      #
      # City budget vs. average grade
      #   schools.country   schools.city      courses.topic     budget      average grade
      #   USA               Boston             (total)           1500         8.3
      #   USA               Boston             Math                           7.5
      #   USA               Boston             Literature                     9.2
      #
      # Cube 3:
      # Budgets for cities that have schools with courses of high international importance factor
      # => NOT SUPPORTED. Cube 3 cannot be added because it shares no grain level
      #   schools.country   schools.city      budget
      #   USA               Boston            1500
      #
      # Alternative via Cube 4:
      # Budgets for cities whose countries have schools with courses of high national importance factor
      #
      # Slices on cubes 1 and 3 get applied on cube 2:
      #   Cube3.importance_factor = high    (courses with high importance factor)
      #   Cube1.budget > 1000               (countries with at least one city budget bigger than 1000)
      #   schools.country = [USA, France, ...]
      #
      #   schools.country    courses.topic   grade
      #
      #
      # The algorithm is as follows:
      #   Go over every "sliced cube" - a cube that has at least one sliced level or metric.
      #   Take every dependent level and restrict its values
      #   Apply the restricted on every cube, including the dependent ones
      #
      # A cube that has no grain and no metric doesn't matter - it can't help with the dependent elements.
      #
      #   USA
      #   schools.city
      #
      #
      #               Authors        Posts            Comments     Reactions
      #           Country  City   Genre   Name     Type   Rating     Rating
      #
      #  Cube 1:    L1.1   L1.2   L2.1    L2.2     L3.1    L3.2
      #  Cube 2:                  L2.1    L2.2     L3.1
      #  Cube 3:                                   L3.1    L3.2      L4.1
      #
      # Scenarios:
      #             L1.1   L1.2   L2.1    L2.2     L3.1    L3.2      L4.1
      #  1-Slice            x                                         x
      #  1-Grain                           x        x
      #  #=> Show comment count by post name and comment type for all posts made by authors from Boston with a positive reaction.
      #
      #  2-Slice                           x
      #  2-Grain                           x                x
      #  #=> Show comment count by post name and comment rating for the post named 'My Thoughts'
      #
      #
      # When we are in #build, the memory slice already occurred, meaning it restricted the elements from cube 1
      # to include only the relevant (L2.2, L3.1) combinations and elements from cube 3 to include only relevant
      # (L3.1) elements.
      # #build then looks at the +intersection+ of L2.2 values and L3.1 values across all cubes.
      #
      def build
        return @entries.first.elements if @entries.length == 1
        @entries.each(&:restrict)
        @entries.flat_map do |entry|
          entry.restricted_elements.each do |element|
            VirtualElement.new
          end
        end
      end

      class ElementsFromSubCube
        include ActiveModel::Model

        attr_accessor :element_locator, :elements, :sliced
        attr_reader :lookups_by_level_id, :unsliced_level_ids_in_grain

        def initialize(elements, sliced, lookups_by_level_id, unsliced_level_ids_in_grain)
          @elements = elements
          @sliced = sliced
          @lookups_by_level_id = lookups_by_level_id

          representative = @elements.first
          @element_locator = representative.element_locator
          @unsliced_level_ids_in_grain = representative.grain_level_ids - (representative.grain_level_ids - unsliced_level_ids_in_grain)
        end

        def restrict
          return unless sliced
          unsliced_level_ids_in_grain.each do |level_id|
            restrict_one_level(level_id)
          end
        end

        def restricted_elements
          unsliced_level_ids_in_grain.inject(elements) do |selected_elements, level_id|
            selected_elements.select do |element|
              value_in_element_for_level = element[level_id]
              lookups_by_level_id[level_id][value_in_element_for_level]
            end
          end
        end

        private

        def restrict_one_level(level_id)
          if lookups_by_level_id.has_key?(level_id)
            lookups_by_level_id[level_id].slice! *(lookups_by_level_id[level_id].keys & values_for(level_id))
          else
            lookup_arr = values_for(level_id).map{|x| [x, true]}
            lookups_by_level_id[level_id] = Hash[lookup_arr]
          end
        end

        def values_for(level_id)
          elements.map{|elm| elm[level_id]}
        end
      end

    end
  end
end
