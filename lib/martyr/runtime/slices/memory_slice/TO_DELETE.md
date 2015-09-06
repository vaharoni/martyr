  # Memory slices are used for two aims:
  #   1. Allow slicing a sub cube that was already built. The slice in this scenario runs on the +facts+.
  #     So if the grain was on 'customers.city', fact records would like like this:
  #           customers.city      customers.state     customers.country     amount_sold
  #           San Francisco       CA                  USA                   100
  #           New York            NY                  USA                   150
  #
  #     and we could apply a slice on any of the levels in the grain:
  #     slice('customers.state', with: 'CA')
  #
  #
  #     Rule 1: Memory slice on a dimension has to be supported by the sub cube grain
  #     We wouldn't be able to slice on a level like 'media_types.name' because we don't have that info:
  #     slice('media_types.name', with: 'MPEG')
  #     # => Error
  #
  #     Now let's assume the sub cube has a slice on a level that is also in it's grain. Maybe like this:
  #     sub_cube.slice('customers.state', with: 'CA').granulate('customers.city')
  #           customers.city      customers.state     customers.country     amount_sold
  #           San Francisco       CA                  USA                   100
  #           Palo Alto           CA                  USA                   37
  #
  #     In this case:
  #     slice('customers.city', with: 'Some City')
  #     # => Is fine
  #
  #     slice('customers.state', with: 'NY')
  #     # => Is fine, but empty
  #
  #
  #     Rule 2: Memory slice on a metric can simply be merged with the sub cube:
  #           Sub Cube Slice              Memory Slice                    Combined Slice
  #           :amount_sold, gt: 100       :amount_sold, gt: 150           :amount_sold, gt: 150
  #
  #
  #  2. Allow changing the current element for custom rollup calculations
  #     Custom rollup naturally occurs within an element.
  #
  #     Elements has a +memory-grain+ which could be different than the sub cube grain.
  #     That said, memory grains MUST be contained within the supported levels of the sub cube grain.
  #
  #     For example:
  #     sub_cube.elements(levels: 'customers.country')
  #     # => Every +element+ would have the 'customers.country' on the grain, which is different than the sub cube's
  #     #    'customers.city' grain. The sub cube supports 'customers.country' because it is a higher level than the
  #          'customers.city' level defined in the grain.
  #
  #     sub_cube.elements(levels: 'media_types.name')
  #     # => Error. media types is not in the sub cube grain.
  #
  #     Every element has two types of slices:
  #     - Endogenous: the current value of every level in the memory grain. E.g.: ['customers.country', with: 'USA']
  #     - Exogenous: the sub cube slice on metrics or levels that are not in the memory grain.
  #       E.g.: ['metrics.units_sold', gt: 100] or ['media_types.name', with: 'MPEG']
  #
  #     With custom rollups, we can do a few things:
  #     (a) ask to override an endogenous level - this is "moving" to a different element within the same memory grain
  #         slice('customers.city', with: 'Paris')
  #         # => Before: {'customers.country' => 'USA', 'customers.city' => {with: 'Boston'} }
  #              After:  {'customers.country' => 'France', 'customers.city' => {with: 'Paris'} }
  #         # => Also note that the entire dimension is reevaluated
  #
  #     (b) ask to remove an endogenous level - this is similar to "bring parent"
  #         reset('customers.city')
  #         # => So if current element coordinates were: {'customers.country' => 'USA', 'customers.city' => {with: 'Boston'} }
  #             we will get an element in a different grain, with coordinates: {'customers.country' => 'USA' }
  #
  #     (c) ask to add exogenous slice - this makes sense only if the slice is supported by the sub cube grain, of course
  #         slice('genres.name', with: 'Rock')
  #         # => Before: {'customers.country' => 'USA', 'customers.city' => {with: 'Boston'} }
  #              After:  {'customers.country' => 'USA', 'customers.city' => {with: 'Boston'}, 'genres.name' => {with: 'Rock'}}
  #
  #
  #       Consider this scenario:
  #
  #             Supported by    Sub cube
  #               Sub cube       slice           Memory Grain
  #       D1.1        *                              *
  #       D1.2        *            *
  #       D1.3        *                              *
  #       D1.4        *
  #       D2.1        *
  #       D2.2
  #
  #       This means that the following scenarios are possible:
  #       1. Override D1.1 - what happens to the current value of D1.3?
  #           Answer:
  #             The element coordinates really represent a slice on D1.3, not D1.1.
  #             When memory slice override is requested on D1.1, it is really requested on D1, which has the effect
  #             of resetting the current slice on this dimension - D1.3, and setting it to D1.1.
  #
  #             To summarize:
  #               Grain:    [D1.3] => [D1.1]
  #
  #       2. Override D1.3 - what happens to the current value of D1.1?
  #           Answer:
  #              Grain does not change. The element coordinates are still [D1.3], but a new element is fetched based
  #              on the requested value of D1.3. Of course, D1.1 moves together with D1.3.
  #
  #       3. Set slice on D1.2 - what happens to the current value of D1.3 and D1.1?
  #           Answer:
  #               Grain changes to [D1.2]. Any value for [D1.3] is reset. [D1.1] is changed with it.
  #
  #       4. Set slice on D1.4 - what happens to current values of D1?
  #           Answer:
  #               Grain changes to [D1.4]. Any value for [D1.3, D1.1] are moved based on the new value for [D1.4]
  #
  #       5. Remove slice [D1.3]
  #               Grain changes to [D1.1]
  #
  #       6. Add slice on [D2.1]
  #             Grain changes to [D1.3, D2.1].
  #
  #     Let's look again at scenarios a through c when a sub cube slice existed in addition on the same dimensions we
  #     are compounding a memory slice on:
  #
  #      # (a) - Overriding element's endogenous slice
  #
  #      (a) Sub Cube grain:      ['customers.last_name']
  #          Sub Cube Slice:      {'customers.country', with: 'USA'}
  #          Memory Grain:        ['customers.city', 'customers.state']
  #          Operation:           slice('customers.city', with: 'Paris')
  #          Current coordinates: {'customers.city' => 'Boston', 'customers.country' => 'USA' }
  #          New coordinates:     <Empty Cell>

  #
  #      (a) Sub Cube grain:      ['customers.last_name']
  #          Sub Cube Slice:      {'customers.country', with: 'USA'}
  #          Memory Grain:        ['customers.city', 'customers.state']
  #          Operation:           slice('customers.city', with: 'San Francisco')
  #          Current coordinates: {'customers.state' => 'MI', 'customers.city' => 'Boston', 'customers.country' => 'USA' }
  #          New coordinates:     {'customers.state' => 'CA', 'customers.city' => 'San Francisco', 'customers.country' => 'USA' }
  #
  #      (a) Sub Cube grain:      ['customers.last_name']
  #          Sub Cube Slice:      {'customers.city', with: 'San Francisco', 'Boston', 'New York'}
  #          Memory Grain:        ['customers.city', 'customers.state']
  #          Operation:           slice('customers.city', with: 'San Francisco')
  #          Current coordinates: {'customers.state' => 'MI', 'customers.city' => 'Boston' }
  #          New coordinates:     {'customers.state' => 'CA', 'customers.city' => 'San Francisco' }
  #
  #     # (b) - Removing endogenous slice
  #
  #      (b) Sub Cube grain:      ['customers.last_name']
  #          Sub Cube Slice:      {'customers.state', with: 'CA'}
  #          Memory Grain:        ['customers.city', 'customers.country', 'customers.state']
  #          Operation:           reset('customers.city')
  #          Current coordinates: {'customers.country' => 'USA', 'customers.city' => 'Boston', 'customers.state' => 'CA' }
  #          New coordinates:     {'customers.country' => 'USA', 'customers.state' => 'CA' }
  #
  #      # NOTE that while the endogenous level is removed, the coordinates keep the exogenous slice!
  #      (b) Sub Cube grain:      ['customers.last_name']
  #          Sub Cube Slice:      {'customers.state', with: 'CA'}
  #          Memory Grain:        ['customers.city', 'customers.country', 'customers.state']
  #          Operation:           reset('customers.state')
  #          Current coordinates: {'customers.country' => 'USA', 'customers.city' => 'Boston', 'customers.state' => 'CA' }
  #          New coordinates:     {'customers.country' => 'USA', 'customers.state' => 'CA' }
  #
  #      # (c) - Adding exogenous slice
  #
  #       # When the exogenous slice is not part of the memory grain
  #      (c) Sub Cube grain:      ['customers.last_name', 'media_types.name']
  #          Sub Cube Slice:      {'customers.state', with: 'CA'}
  #          Memory Grain:        ['customers.city', 'customers.country']
  #          Operation:           slice('media_types.name', with: 'MPEG')
  #          Current coordinates: {'customers.country' => 'USA', 'customers.city' => 'Boston', 'customers.state' => 'CA' }
  #          New coordinates:     {'customers.country' => 'USA', 'customers.city' => 'Boston', 'customers.state' => 'CA', 'media_types.name' => 'MPEG' }
  #
  #      # When exogesnour
  #      (c) Sub Cube grain:      ['customers.last_name']
  #          Sub Cube Slice:      {'customers.city', with: 'San Francisco', 'Boston', 'New York'}
  #          Memory Grain:        ['customers.state']
  #          Operation:           slice('customers.city', with: 'San Francisco')
  #          Current coordinates: {'customers.state' => 'MI' }
  #          New coordinates:     <Empty Element>
  #
  #
  #     q = Cube.slice('customers.state', with: ['CA', 'NY', 'YS', 'BC']).granulate('customers.last_name', 'media_types.name').build
  #     all =    q.elements(levels: ['customers.country', 'customers.city'])
  #     slice1 = q.slice('customers.state', with: 'NY').elements(levels: ['customers.country', 'customers.city'])
  #         # => The merging of slices is simple - it's on the same level
  #     slice2 = q.slice('customers.country', with: 'Canada').elements(levels: ['customers.country', 'customers.city'])
  #         # => The merging of slices is hard - it needs to go to the dimension, similar to coordinates resolver
  #     slice3 = q.slice('customers.city', with: 'Paris').elements(levels: ['customers.country', 'customers.city'])
  #         # => The merging of slices is medium - it will either be null or Paris.
  #
  #   Memory slice and coordinate resolver are very similar! Coordinate resolver is basically applying a memory slice
  #   on the current element values. The only exception is that for coordinate resolver, slice3 is easy - it is assumed
  #   to exist.
