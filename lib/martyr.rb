require 'martyr/version'

require 'csv'
require 'active_support'
require 'active_support/core_ext'
require 'active_model'
require 'active_record'

require_relative 'martyr/errors'

module Martyr
  autoload :Translations, File.expand_path('../martyr/helpers/translations', __FILE__)
  autoload :Delegators, File.expand_path('../martyr/helpers/delegators', __FILE__)
  autoload :IntervalSet, File.expand_path('../martyr/helpers/intervals', __FILE__)
  autoload :Interval, File.expand_path('../martyr/helpers/intervals', __FILE__)
  autoload :PointInterval, File.expand_path('../martyr/helpers/intervals', __FILE__)
  autoload :MetricIdStandardizer, File.expand_path('../martyr/helpers/metric_id_standardizer', __FILE__)
  autoload :Registrable, File.expand_path('../martyr/helpers/registrable', __FILE__)
  autoload :Sorter, File.expand_path('../martyr/helpers/sorter', __FILE__)

  autoload :HasLevelCollection, File.expand_path('../martyr/level_concern/has_level_collection', __FILE__)
  autoload :Level, File.expand_path('../martyr/level_concern/level', __FILE__)
  autoload :LevelCollection, File.expand_path('../martyr/level_concern/level_collection', __FILE__)
  autoload :LevelComparator, File.expand_path('../martyr/level_concern/level_comparator', __FILE__)
  autoload :LevelDefinitionsByDimension, File.expand_path('../martyr/level_concern/level_definitions_by_dimension', __FILE__)

  autoload :BaseCube, File.expand_path('../martyr/base_cube', __FILE__)
  autoload :Cube, File.expand_path('../martyr/cube', __FILE__)
  autoload :DimensionReference, File.expand_path('../martyr/dimension_reference', __FILE__)
  autoload :VirtualCube, File.expand_path('../martyr/virtual_cube', __FILE__)

  module Schema
    autoload :DimensionAssociationCollection, File.expand_path('../martyr/schema/dimension_associations/dimension_association_collection', __FILE__)
    autoload :LevelAssociation, File.expand_path('../martyr/schema/dimension_associations/level_association', __FILE__)
    autoload :LevelAssociationCollection, File.expand_path('../martyr/schema/dimension_associations/level_association_collection', __FILE__)
    autoload :DimensionDefinitionCollection, File.expand_path('../martyr/schema/dimensions/dimension_definition_collection', __FILE__)
    autoload :PlainDimensionDefinition, File.expand_path('../martyr/schema/dimensions/plain_dimension_definition', __FILE__)
    autoload :BaseFactDefinition, File.expand_path('../martyr/schema/facts/base_fact_definition', __FILE__)
    autoload :FactDefinitionCollection, File.expand_path('../martyr/schema/facts/fact_definition_collection', __FILE__)
    autoload :MainFactDefinition, File.expand_path('../martyr/schema/facts/main_fact_definition', __FILE__)
    autoload :SubFactDefinition, File.expand_path('../martyr/schema/facts/sub_fact_definition', __FILE__)
    autoload :BaseMetric, File.expand_path('../martyr/schema/metrics/base_metric', __FILE__)
    autoload :BuiltInMetric, File.expand_path('../martyr/schema/metrics/built_in_metric', __FILE__)
    autoload :CountDistinctMetric, File.expand_path('../martyr/schema/metrics/count_distinct_metric', __FILE__)
    autoload :CustomMetric, File.expand_path('../martyr/schema/metrics/custom_metric', __FILE__)
    autoload :CustomRollup, File.expand_path('../martyr/schema/metrics/custom_rollup', __FILE__)
    autoload :DependencyInferrer, File.expand_path('../martyr/schema/metrics/dependency_inferrer', __FILE__)
    autoload :MetricDefinitionCollection, File.expand_path('../martyr/schema/metrics/metric_definition_collection', __FILE__)
    autoload :NamedScope, File.expand_path('../martyr/schema/named_scopes/named_scope', __FILE__)
    autoload :NamedScopeCollection, File.expand_path('../martyr/schema/named_scopes/named_scope_collection', __FILE__)
    autoload :BaseLevelDefinition, File.expand_path('../martyr/schema/plain_dimension_levels/base_level_definition', __FILE__)
    autoload :DegenerateLevelDefinition, File.expand_path('../martyr/schema/plain_dimension_levels/degenerate_level_definition', __FILE__)
    autoload :LevelDefinitionCollection, File.expand_path('../martyr/schema/plain_dimension_levels/level_definition_collection', __FILE__)
    autoload :QueryLevelDefinition, File.expand_path('../martyr/schema/plain_dimension_levels/query_level_definition', __FILE__)
  end

  module Runtime
    autoload :Coordinates, File.expand_path('../martyr/runtime/data_set/coordinates', __FILE__)
    autoload :Element, File.expand_path('../martyr/runtime/data_set/element', __FILE__)
    autoload :ElementCommon, File.expand_path('../martyr/runtime/data_set/element_common', __FILE__)
    autoload :ElementLocator, File.expand_path('../martyr/runtime/data_set/element_locator', __FILE__)
    autoload :Fact, File.expand_path('../martyr/runtime/data_set/fact', __FILE__)
    autoload :FactIndexer, File.expand_path('../martyr/runtime/data_set/fact_indexer', __FILE__)
    autoload :FutureFactValue, File.expand_path('../martyr/runtime/data_set/future_fact_value', __FILE__)
    autoload :FutureMetric, File.expand_path('../martyr/runtime/data_set/future_metric', __FILE__)
    autoload :VirtualElement, File.expand_path('../martyr/runtime/data_set/virtual_element', __FILE__)
    autoload :VirtualElementsBuilder, File.expand_path('../martyr/runtime/data_set/virtual_elements_builder', __FILE__)
    autoload :BaseLevelScope, File.expand_path('../martyr/runtime/dimension_scopes/base_level_scope', __FILE__)
    autoload :DegenerateLevelScope, File.expand_path('../martyr/runtime/dimension_scopes/degenerate_level_scope', __FILE__)
    autoload :DimensionScopeCollection, File.expand_path('../martyr/runtime/dimension_scopes/dimension_scope_collection', __FILE__)
    autoload :LevelScopeCollection, File.expand_path('../martyr/runtime/dimension_scopes/level_scope_collection', __FILE__)
    autoload :QueryLevelScope, File.expand_path('../martyr/runtime/dimension_scopes/query_level_scope', __FILE__)
    autoload :BaseFactScope, File.expand_path('../martyr/runtime/fact_scopes/base_fact_scope', __FILE__)
    autoload :FactScopeCollection, File.expand_path('../martyr/runtime/fact_scopes/fact_scope_collection', __FILE__)
    autoload :MainFactScope, File.expand_path('../martyr/runtime/fact_scopes/main_fact_scope', __FILE__)
    autoload :NullScope, File.expand_path('../martyr/runtime/fact_scopes/null_scope', __FILE__)
    autoload :SubFactScope, File.expand_path('../martyr/runtime/fact_scopes/sub_fact_scope', __FILE__)
    autoload :WrappedFactScope, File.expand_path('../martyr/runtime/fact_scopes/wrapped_fact_scope', __FILE__)
    autoload :PivotAxis, File.expand_path('../martyr/runtime/pivot/pivot_axis', __FILE__)
    autoload :PivotCell, File.expand_path('../martyr/runtime/pivot/pivot_cell', __FILE__)
    autoload :PivotGrainElement, File.expand_path('../martyr/runtime/pivot/pivot_grain_element', __FILE__)
    autoload :PivotRow, File.expand_path('../martyr/runtime/pivot/pivot_row', __FILE__)
    autoload :PivotTable, File.expand_path('../martyr/runtime/pivot/pivot_table', __FILE__)
    autoload :PivotTableBuilder, File.expand_path('../martyr/runtime/pivot/pivot_table_builder', __FILE__)
    autoload :MetricDependencyResolver, File.expand_path('../martyr/runtime/query/metric_dependency_resolver', __FILE__)
    autoload :QueryContext, File.expand_path('../martyr/runtime/query/query_context', __FILE__)
    autoload :QueryContextBuilder, File.expand_path('../martyr/runtime/query/query_context_builder', __FILE__)
    autoload :BaseOperator, File.expand_path('../martyr/runtime/scope_operators/base_operator', __FILE__)
    autoload :GroupOperator, File.expand_path('../martyr/runtime/scope_operators/group_operator', __FILE__)
    autoload :SelectOperatorForDimension, File.expand_path('../martyr/runtime/scope_operators/select_operator_for_dimension', __FILE__)
    autoload :SelectOperatorForMetric, File.expand_path('../martyr/runtime/scope_operators/select_operator_for_metric', __FILE__)
    autoload :WhereOperatorForDimension, File.expand_path('../martyr/runtime/scope_operators/where_operator_for_dimension', __FILE__)
    autoload :WhereOperatorForMetric, File.expand_path('../martyr/runtime/scope_operators/where_operator_for_metric', __FILE__)
    autoload :DataSlice, File.expand_path('../martyr/runtime/slices/data_slices/data_slice', __FILE__)
    autoload :MetricDataSlice, File.expand_path('../martyr/runtime/slices/data_slices/metric_data_slice', __FILE__)
    autoload :PlainDimensionDataSlice, File.expand_path('../martyr/runtime/slices/data_slices/plain_dimension_data_slice', __FILE__)
    autoload :TimeDimensionDataSlice, File.expand_path('../martyr/runtime/slices/data_slices/time_dimension_data_slice', __FILE__)
    autoload :HasScopedLevels, File.expand_path('../martyr/runtime/slices/has_scoped_levels', __FILE__)
    autoload :MemorySlice, File.expand_path('../martyr/runtime/slices/memory_slices/memory_slice', __FILE__)
    autoload :MetricMemorySlice, File.expand_path('../martyr/runtime/slices/memory_slices/metric_memory_slice', __FILE__)
    autoload :PlainDimensionMemorySlice, File.expand_path('../martyr/runtime/slices/memory_slices/plain_dimension_memory_slice', __FILE__)
    autoload :ScopeableSliceData, File.expand_path('../martyr/runtime/slices/scopeable_slice_data', __FILE__)
    autoload :BaseSliceDefinition, File.expand_path('../martyr/runtime/slices/slice_definitions/base_slice_definition', __FILE__)
    autoload :MetricSliceDefinition, File.expand_path('../martyr/runtime/slices/slice_definitions/metric_slice_definition', __FILE__)
    autoload :PlainDimensionLevelSliceDefinition, File.expand_path('../martyr/runtime/slices/slice_definitions/plain_dimension_level_slice_definition', __FILE__)
    autoload :QueryMetrics, File.expand_path('../martyr/runtime/sub_cubes/query_metrics', __FILE__)
    autoload :SubCube, File.expand_path('../martyr/runtime/sub_cubes/sub_cube', __FILE__)
    autoload :SubCubeGrain, File.expand_path('../martyr/runtime/sub_cubes/sub_cube_grain', __FILE__)

    module FactFillerStrategies
      autoload :DegenerateLevelAssociationFillerStrategy, File.expand_path('../martyr/runtime/sub_cubes/fact_filler_strategies', __FILE__)
      autoload :QueryLevelAssociationFillerStrategy, File.expand_path('../martyr/runtime/sub_cubes/fact_filler_strategies', __FILE__)
      autoload :UnassociatedLevelFillerStrategy, File.expand_path('../martyr/runtime/sub_cubes/fact_filler_strategies', __FILE__)
    end
  end
end
