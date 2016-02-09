require 'martyr/version'

require 'csv'
require 'active_support'
require 'active_support/core_ext'
require 'active_model'
require 'active_record'

require_relative 'martyr/errors'

module Martyr
  autoload :Translations, File.expand_path('lib/martyr/helpers/translations')
  autoload :Delegators, File.expand_path('lib/martyr/helpers/delegators')
  autoload :IntervalSet, File.expand_path('lib/martyr/helpers/intervals')
  autoload :Interval, File.expand_path('lib/martyr/helpers/intervals')
  autoload :PointInterval, File.expand_path('lib/martyr/helpers/intervals')
  autoload :MetricIdStandardizer, File.expand_path('lib/martyr/helpers/metric_id_standardizer')
  autoload :Registrable, File.expand_path('lib/martyr/helpers/registrable')
  autoload :Sorter, File.expand_path('lib/martyr/helpers/sorter')

  autoload :HasLevelCollection, File.expand_path('lib/martyr/level_concern/has_level_collection')
  autoload :Level, File.expand_path('lib/martyr/level_concern/level')
  autoload :LevelCollection, File.expand_path('lib/martyr/level_concern/level_collection')
  autoload :LevelComparator, File.expand_path('lib/martyr/level_concern/level_comparator')
  autoload :LevelDefinitionsByDimension, File.expand_path('lib/martyr/level_concern/level_definitions_by_dimension')

  autoload :BaseCube, File.expand_path('lib/martyr/base_cube')
  autoload :Cube, File.expand_path('lib/martyr/cube')
  autoload :DimensionReference, File.expand_path('lib/martyr/dimension_reference')
  autoload :VirtualCube, File.expand_path('lib/martyr/virtual_cube')

  module Schema
    autoload :DimensionAssociationCollection, File.expand_path('lib/martyr/schema/dimension_associations/dimension_association_collection')
    autoload :LevelAssociation, File.expand_path('lib/martyr/schema/dimension_associations/level_association')
    autoload :LevelAssociationCollection, File.expand_path('lib/martyr/schema/dimension_associations/level_association_collection')
    autoload :DimensionDefinitionCollection, File.expand_path('lib/martyr/schema/dimensions/dimension_definition_collection')
    autoload :PlainDimensionDefinition, File.expand_path('lib/martyr/schema/dimensions/plain_dimension_definition')
    autoload :BaseFactDefinition, File.expand_path('lib/martyr/schema/facts/base_fact_definition')
    autoload :FactDefinitionCollection, File.expand_path('lib/martyr/schema/facts/fact_definition_collection')
    autoload :MainFactDefinition, File.expand_path('lib/martyr/schema/facts/main_fact_definition')
    autoload :SubFactDefinition, File.expand_path('lib/martyr/schema/facts/sub_fact_definition')
    autoload :BaseMetric, File.expand_path('lib/martyr/schema/metrics/base_metric')
    autoload :BuiltInMetric, File.expand_path('lib/martyr/schema/metrics/built_in_metric')
    autoload :CountDistinctMetric, File.expand_path('lib/martyr/schema/metrics/count_distinct_metric')
    autoload :CustomMetric, File.expand_path('lib/martyr/schema/metrics/custom_metric')
    autoload :CustomRollup, File.expand_path('lib/martyr/schema/metrics/custom_rollup')
    autoload :DependencyInferrer, File.expand_path('lib/martyr/schema/metrics/dependency_inferrer')
    autoload :MetricDefinitionCollection, File.expand_path('lib/martyr/schema/metrics/metric_definition_collection')
    autoload :NamedScope, File.expand_path('lib/martyr/schema/named_scopes/named_scope')
    autoload :NamedScopeCollection, File.expand_path('lib/martyr/schema/named_scopes/named_scope_collection')
    autoload :BaseLevelDefinition, File.expand_path('lib/martyr/schema/plain_dimension_levels/base_level_definition')
    autoload :DegenerateLevelDefinition, File.expand_path('lib/martyr/schema/plain_dimension_levels/degenerate_level_definition')
    autoload :LevelDefinitionCollection, File.expand_path('lib/martyr/schema/plain_dimension_levels/level_definition_collection')
    autoload :QueryLevelDefinition, File.expand_path('lib/martyr/schema/plain_dimension_levels/query_level_definition')
  end

  module Runtime
    autoload :Coordinates, File.expand_path('lib/martyr/runtime/data_set/coordinates')
    autoload :Element, File.expand_path('lib/martyr/runtime/data_set/element')
    autoload :ElementCommon, File.expand_path('lib/martyr/runtime/data_set/element_common')
    autoload :ElementLocator, File.expand_path('lib/martyr/runtime/data_set/element_locator')
    autoload :Fact, File.expand_path('lib/martyr/runtime/data_set/fact')
    autoload :FactIndexer, File.expand_path('lib/martyr/runtime/data_set/fact_indexer')
    autoload :FutureFactValue, File.expand_path('lib/martyr/runtime/data_set/future_fact_value')
    autoload :FutureMetric, File.expand_path('lib/martyr/runtime/data_set/future_metric')
    autoload :VirtualElement, File.expand_path('lib/martyr/runtime/data_set/virtual_element')
    autoload :VirtualElementsBuilder, File.expand_path('lib/martyr/runtime/data_set/virtual_elements_builder')
    autoload :BaseLevelScope, File.expand_path('lib/martyr/runtime/dimension_scopes/base_level_scope')
    autoload :DegenerateLevelScope, File.expand_path('lib/martyr/runtime/dimension_scopes/degenerate_level_scope')
    autoload :DimensionScopeCollection, File.expand_path('lib/martyr/runtime/dimension_scopes/dimension_scope_collection')
    autoload :LevelScopeCollection, File.expand_path('lib/martyr/runtime/dimension_scopes/level_scope_collection')
    autoload :QueryLevelScope, File.expand_path('lib/martyr/runtime/dimension_scopes/query_level_scope')
    autoload :BaseFactScope, File.expand_path('lib/martyr/runtime/fact_scopes/base_fact_scope')
    autoload :FactScopeCollection, File.expand_path('lib/martyr/runtime/fact_scopes/fact_scope_collection')
    autoload :MainFactScope, File.expand_path('lib/martyr/runtime/fact_scopes/main_fact_scope')
    autoload :NullScope, File.expand_path('lib/martyr/runtime/fact_scopes/null_scope')
    autoload :SubFactScope, File.expand_path('lib/martyr/runtime/fact_scopes/sub_fact_scope')
    autoload :WrappedFactScope, File.expand_path('lib/martyr/runtime/fact_scopes/wrapped_fact_scope')
    autoload :PivotAxis, File.expand_path('lib/martyr/runtime/pivot/pivot_axis')
    autoload :PivotCell, File.expand_path('lib/martyr/runtime/pivot/pivot_cell')
    autoload :PivotGrainElement, File.expand_path('lib/martyr/runtime/pivot/pivot_grain_element')
    autoload :PivotRow, File.expand_path('lib/martyr/runtime/pivot/pivot_row')
    autoload :PivotTable, File.expand_path('lib/martyr/runtime/pivot/pivot_table')
    autoload :PivotTableBuilder, File.expand_path('lib/martyr/runtime/pivot/pivot_table_builder')
    autoload :MetricDependencyResolver, File.expand_path('lib/martyr/runtime/query/metric_dependency_resolver')
    autoload :QueryContext, File.expand_path('lib/martyr/runtime/query/query_context')
    autoload :QueryContextBuilder, File.expand_path('lib/martyr/runtime/query/query_context_builder')
    autoload :BaseOperator, File.expand_path('lib/martyr/runtime/scope_operators/base_operator')
    autoload :GroupOperator, File.expand_path('lib/martyr/runtime/scope_operators/group_operator')
    autoload :SelectOperatorForDimension, File.expand_path('lib/martyr/runtime/scope_operators/select_operator_for_dimension')
    autoload :SelectOperatorForMetric, File.expand_path('lib/martyr/runtime/scope_operators/select_operator_for_metric')
    autoload :WhereOperatorForDimension, File.expand_path('lib/martyr/runtime/scope_operators/where_operator_for_dimension')
    autoload :WhereOperatorForMetric, File.expand_path('lib/martyr/runtime/scope_operators/where_operator_for_metric')
    autoload :DataSlice, File.expand_path('lib/martyr/runtime/slices/data_slices/data_slice')
    autoload :MetricDataSlice, File.expand_path('lib/martyr/runtime/slices/data_slices/metric_data_slice')
    autoload :PlainDimensionDataSlice, File.expand_path('lib/martyr/runtime/slices/data_slices/plain_dimension_data_slice')
    autoload :TimeDimensionDataSlice, File.expand_path('lib/martyr/runtime/slices/data_slices/time_dimension_data_slice')
    autoload :HasScopedLevels, File.expand_path('lib/martyr/runtime/slices/has_scoped_levels')
    autoload :MemorySlice, File.expand_path('lib/martyr/runtime/slices/memory_slices/memory_slice')
    autoload :MetricMemorySlice, File.expand_path('lib/martyr/runtime/slices/memory_slices/metric_memory_slice')
    autoload :PlainDimensionMemorySlice, File.expand_path('lib/martyr/runtime/slices/memory_slices/plain_dimension_memory_slice')
    autoload :ScopeableSliceData, File.expand_path('lib/martyr/runtime/slices/scopeable_slice_data')
    autoload :BaseSliceDefinition, File.expand_path('lib/martyr/runtime/slices/slice_definitions/base_slice_definition')
    autoload :MetricSliceDefinition, File.expand_path('lib/martyr/runtime/slices/slice_definitions/metric_slice_definition')
    autoload :PlainDimensionLevelSliceDefinition, File.expand_path('lib/martyr/runtime/slices/slice_definitions/plain_dimension_level_slice_definition')
    autoload :QueryMetrics, File.expand_path('lib/martyr/runtime/sub_cubes/query_metrics')
    autoload :SubCube, File.expand_path('lib/martyr/runtime/sub_cubes/sub_cube')
    autoload :SubCubeGrain, File.expand_path('lib/martyr/runtime/sub_cubes/sub_cube_grain')

    module FactFillerStrategies
      autoload :DegenerateLevelAssociationFillerStrategy, File.expand_path('lib/martyr/runtime/sub_cubes/fact_filler_strategies')
      autoload :QueryLevelAssociationFillerStrategy, File.expand_path('lib/martyr/runtime/sub_cubes/fact_filler_strategies')
      autoload :UnassociatedLevelFillerStrategy, File.expand_path('lib/martyr/runtime/sub_cubes/fact_filler_strategies')
    end
  end
end
