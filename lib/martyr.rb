require 'martyr/version'

require 'active_support'
require 'active_support/core_ext'
require 'active_model'

Dir.glob('lib/martyr/**/*.*').each{|x| require File.expand_path(x).split('.rb').first}

# require 'martyr/base'
# require 'martyr/errors'
#
# require 'martyr/schema/concerns/registrable'
# require 'martyr/schema/concerns/has_scope'
#
# require 'martyr/schema/dimensions/dimension_definition'
# require 'martyr/schema/dimensions/degenerate_dimension'
# require 'martyr/schema/dimensions/query_dimension'
# require 'martyr/schema/dimensions/time_dimension'
# require 'martyr/schema/dimensions/dimension_definition_collection'
# require 'martyr/schema/dimensions/shared_dimension_wrapper'
# require 'martyr/schema/dimensions/level_collection'
# require 'martyr/schema/dimensions/level'
#
# require 'martyr/schema/facts/fact_definition_collection'
# require 'martyr/schema/facts/main_fact_scope'
# require 'martyr/schema/facts/sub_fact_scope'
#
# require 'martyr/schema/metrics/built_in_metric'
# require 'martyr/schema/metrics/custom_metric'
# require 'martyr/schema/metrics/metric_definition_collection'
#
# require 'martyr/schema/rollups/custom_rollup'
# require 'martyr/schema/rollups/rollup_definition_collection'
#
# require 'martyr/runtime/query/query_context'
#
# require 'martyr/runtime/slices/base_dimension_slice'
# require 'martyr/runtime/slices/compound_slice'
# require 'martyr/runtime/slices/degenerate_dimension_slice'
# require 'martyr/runtime/slices/metric_slice'
# require 'martyr/runtime/slices/query_dimension_slice'
# require 'martyr/runtime/slices/time_dimension_slice'

module Martyr
  # Your code goes here...
end
