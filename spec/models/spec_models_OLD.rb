module MartyrSpec
  class Common < Martyr::Cube
    add_query_dimension :customer
    add_query_dimension :album
    add_query_dimension :track
    add_query_dimension :genre
    add_query_dimension :media_type
  end

  class TrackSalesMartBasic < Common
    add_degenerate_dimension :customer_country, 'customers.country'
    add_degenerate_dimension :customer_city, 'customers.city'
    use_shared_dimension :customer, 'customers.id'

    use_shared_dimension :album, 'tracks.album_id'
    use_shared_dimension :track, 'tracks.id'
    use_shared_dimension :genre, 'tracks.genre_id'
    use_shared_dimension :media_type, 'tracks.media_type_id'

    add_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
    add_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

    main_fact do
      InvoiceLine.joins(:track, invoice: :customer)
    end
  end


  # Every fact has the following:
  # m metrics - M1, M2, ...
  # d dimension - D1, D2, ...
  # Every dimension has levels - D1.1, D1.2, D1.3, ... D2.1, D2.2, ... Level 1 is the leaf, level 2 is a rollup
  # Every dimension level has values - D1.1.1, D1.1.2, ... D1.2.1, ....
  #
  # Definition of cell coordinates:
  #   One metric
  #   Optional dimension value for ONE (the lower) level.
  # Tuple: (metric: M1, D1 => {level: 2, with: 'D1.2.5'})
  #
  # These coordinates represent a group of facts that have to be rolled-up somehow.
  #
  # Levels are a representation of one-to-many relationship.
  #   Department
  #     Invoices
  #       Invoice Line
  #
  #
  # Martyr takes advantage of Active Record for this, by following the following convention:
  #
  #   # Invoice Hierarchy Dimension
  #     ## Level 3: `department`
  #         ### Active Record Entity: Department
  #         ### To get to next level, calls the method :invoices. To get to the lower level, calls :invoice_lines
  #         ### For Join Strategy it calls joins(:invoice)
  #
  #     ## Level 2: `invoices`
  #         ### Active Record Entity: Invoice
  #         ### To get to next level, calls the method :invoice_lines. To get to the previous level, calls :department
  #         ### For Join Strategy it calls joins(:invoice_lines) or joins(:department)
  #
  #     ## Level 1: `invoice_lines`
  #         ### Active Record Entity: InvoiceLine
  #         ### To drill-up, calls the method :invoice, to drill all the way up, calls :department.
  #         ### For Join Strategy it calls joins(:invoice_lines) or joins(:invoices)
  #
  # Martyr can also use degenerate_level which means it does not have an active record entity:
  #   Product Category
  #     Product Sub Category
  #       Product
  #
  #   # Products Dimension
  #     ## Level 3: `category`, degenerate
  #     ## Level 2: `sub_category`, degenerate
  #     ## Level 1: `product`
  #       ## Active Record Entity: Product
  #       ## `category` and `sub_category` methods are called
  #       ## category needs to tell us how to retrieve children
  #
  #  About levels:
  #   1. DIMENSION: As soon as one level is considered degenerate, all levels above it must be degenerate.
  #   2. FACT: If degenerate level is directly connected to the fact, all levels above it must be connected to the fact.
  #
  #   *. If degenerate level is above query level, it must provide custom ways to perform WHERE on the NEXT query level
  #
  #
  #      Level Type       Connected to Fact?      Operation        Example        Strategy
  #      Query             Yes                     WHERE            A1            Separate dimension query, WHERE on IDs
  #      Query             Yes                     GROUP BY         A1            Group by on the column on the fact
  #      Query             No                      WHERE            A4            Separate dimension query with :includes, WHERE on IDs
  #      Query             No                      GROUP BY         A4            The grouping will be performed in memory
  #
  #      Degenerate        Yes                     WHERE            A1            No dimension query - straight to the fact
  #      Degenerate        Yes                     GROUP BY         A1            Group by on the column on the fact
  #      Degenerate        No                      WHERE            A4            Performs a query on the query dimension (must exist according to rules)
  #      Degenerate        No                      GROUP BY         A4
  #
  #
  # Use cases, assuming D1.1, D1.2 where D1.1 is leaf level of D1:
  #
  #  A. Cube #1, with has_level D1.1 only:
  #       Slice               Group Statement     Effective Group     Result
  #  (1)* D1.1                  D1.1               D1.1               GROUP BY on D1.1, WHERE on D1.1
  #  (2)  D1.1                  D1.2               D1.1               Equivalent to A1
  #  (3)* D1.2                  D1.1               D1.1               Query on D1.2 to retrieve D1.1 IDs, WHERE on D1.1 IDs
  #  (4)  D1.2                  D1.2               D1.1               Equivalent to A3
  #  (5)  D1.1                  D1.1, D1.2         D1.1               Equivalent to A3
  #  (6)  D1.2                  D1.1, D1.2         D1.1               Equivalent to A3
  #
  #  B. Cube #2, with has_level D1.2 only:
  #       Slice               Group Statement     Effective Group     Result
  #  (1)  D1.1                  D1.1               N/A                Equivalent to B2
  #  (2)* D1.1                  D1.2               N/A                Null results: Slicing on level that is not defined in cube.
  #  (3)  D1.2                  D1.1               D1.2               Equivalent to B4
  #  (4)* D1.2                  D1.2               D1.2               WHERE on D1.2
  #  (5)  D1.1                  D1.1, D1.2         N/A                Equivalent to B2
  #  (6)  D1.2                  D1.1, D1.2         D1.2               Equivalent to B4
  #
  #  C. Cube #3, with has_level D1.1 and D1.2:
  #       Slice               Group Statement     Effective Group     Result
  #  (1)  D1.1                  D1.1               D1.1, D1.2         Equivalent to C5
  #  (2)  D1.1                  D1.2               D1.1, D1.2         Equivalent to C5
  #  (3)  D1.2                  D1.1               D1.1, D1.2         Equivalent to C6
  #  (4)* D1.2                  D1.2               D1.2               GROUP BY on D1.2, WHERE on D1.2
  #  (5)* D1.1                  D1.1, D1.2         D1.1, D1.2         GROUP BY on D1.1 & D1.2, WHERE on D1.1.
  #  (6)* D1.2                  D1.1, D1.2         D1.1, D1.2         GROUP BY on D1.1 & D1.2, WHERE on D1.2.
  #
  #
  #   Cube  Support               Slice           Group By            Where
  #   (D1.1)                      D1.1            D1.1                Direct
  #   (D1.1)                      D1.2            D1.1                Through D1.1 IDs
  #   (D1.1)                      D1.3            D1.1                Through D1.1 IDs
  #
  #   (D1.2)                      D1.1            Null
  #   (D1.2)                      D1.2            D1.2                Direct
  #   (D1.2)                      D1.3            D1.2                Through D1.2 IDs; note that D1.2 cannot be degenerate, otherwise D1.3 must always be connected
  #
  #   (D1.1, D1.2)                D1.1            D1.1, D1.2          Direct
  #   (D1.1, D1.2)                D1.2            D1.2                Direct
  #   (D1.1, D1.2)                D1.3            D1.2                Through D1.2 IDs
  #
  #   (D1.1, D1.3)                D1.1            D1.1, D1.3          Direct
  #   (D1.1, D1.3)                D1.2            D1.1, D1.3          Through D1.1 IDs
  #   (D1.1, D1.3)                D1.3            D1.3                Direct
  #
  #   (D1.1, D1.2, D1.3)          D1.1            D1.1, D1.2, D1.3    Direct
  #   (D1.1, D1.2, D1.3)          D1.2            D1.2, D1.3          Direct
  #   (D1.1, D1.2, D1.3)          D1.3            D1.3                Direct
  #
  #
  #   (D1.2, D1.3)                D1.1            Null
  #   (D1.2, D1.3)                D1.2            D1.2, D1.3          Direct
  #   (D1.2, D1.3)                D1.2            D1.3                Direct
  #
  #   (D1.3)                      D1.1            Null
  #   (D1.3)                      D1.2            Null
  #   (D1.3)                      D1.3            D1.3                Direct
  #
  # A few things to note:
  #   - If the cube supports the sliced level, `group` automatically includes it and all levels above it that the cube
  #     supports.
  #   - If the cube does not support the sliced level, `group` goes down to the first supported level. If none exists,
  #     the subcube is the null cube.
  #   - The only good reason behind `group` is to include a +lower level+ than the `slice`.
  #   - Calculated metrics, selected using `select` expand the `group` without affecting `slice`.
  #   - This means that in most cases `group` is not needed at all.
  #
  #
  # Advantage:
  #   Knowing a cell coordinates mean that we can easily traverse between similar cubes with shared dimensions.
  #
  #       Class Context
  #           Dimension definitions
  #           Main Fact definition
  #               Dimension Association
  #           Sub Fact Definition
  #               Dimension Association
  #
  #
  #       Dimension
  #           name          :product
  #
  #     ------------------------------------------------------------------------------------------------------
  #         Query Level
  #           name          :name
  #           scope         -> { Product.all }
  #           primary_key   :id
  #           label_key     :name     (similar to level_name)
  #
  #           When connecting to fact:
  #             fact_key      :product_id       / 'products.id'
  #             fact_alias    :product_id
  #
  #     ------------------------------------------------------------------------------------------------------
  #
  #         Degenerate Level
  #           name                        :category
  #           query_level_key             :category
  #           query_level_with_finder     ->(value) { query_level.scope.where(query_level_key => value) }
  #           query_level_without_finder  ->(value) { query_level.scope.where.not(category: value) }
  #
  #           When connecting to fact:
  #             fact_key      :product_category  / 'products.category'
  #             fact_alias    :product_category
  #
  #
  #


  class Schema1 < Martyr::Cube
    # Query dimension - with scope.
    # This means that as long as the lowest level is defined with `has_dimension_level`, the other levels can be inferred
    # in memory as it assumes Customer has the methods #country, #state, #city and #name.
    dimension :customer, title: 'Customer' do
      degenerate_level :country, primary_key: 'customer_country', label_key: 'customer_country', title: 'Country'
      degenerate_level :state, primary_key: 'customer_state', label_key: 'customer_state', title: 'State'
      query_level :name, primary_key: 'id', label_key: 'customer_name', fact_key: 'customer_id', title: 'Name'
    end

    dimension :album, title: 'Album' do
      degenerate_level :name, primary_key: 'id', label_key: 'name', title: 'Album name'
    end

    dimension :category, title: 'Category / Subcategory' do
      degenerate_level :category, title: 'Category'
      degenerate_level :sub_category, title: 'Sub category'
    end

    time_dimension :creation_date, title: 'Creation Date', levels: [:month, :quarter, :year]
  end

  # This will allow doing things like
  # cube = Test1.select(:units_sold).group(customer: :name).slice(:units_sold, gt: 0)
  # cube.facts.first.customer
  # cube.pivot.on_columns(:units_sold).on_columns(customer: :country, customer: :state)
  #
  # cube2 = Test1.select(:units_sold).group(customer: :country)
  # # => Will automatically perform a join on the dimension to group by country
  #
  # cube3 = Test1.slice(customer: {level: :country, with: 'USA'}, units_sold: {gt: 0})
  # # => Will automatically perform a join on the dimension to slice on country. Can still do:
  # # => Note that for consistency, the result of the join WILL NOT be a part of the SELECT clause, only the WHERE
  # cube3.facts.first.customer
  #
  class Test1 < Schema1
    main_fact do
      has_dimension_level :customer, level: 'name', fact_key: 'customers.id', fact_alias: 'customer_id'
      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'

      query do
        InvoiceLine.joins(:track, invoice: :customer)
      end
    end
  end

  # This will allow doing things like
  # cube = Test1.select(:units_sold).group(customer: :state).slice(:units_sold, gt: 0)
  # cube.pivot.on_columns(:units_sold).on_columns(customer: :country, customer: :state)
  #
  # This time, in order to retrieve the customers, one should do:
  #   cube.facts.first.coordinates
  #   # => {metric: :units_sold, customer: {level: :country, with: 'USA'}, units_sold: {gt: 0}}
  #
  #   # This is not allowed, because we can't guarantee that customers we fetch actually had units sold greater than 0
  #   cube.facts.first.customers
  #
  class Test2 < Schema1
    main_fact do
      has_dimension_level :customer, level: 'name', fact_key: 'customers.id', fact_alias: 'customer_id'
      has_dimension_level :customer, level: 'state', fact_key: 'customers.state', fact_alias: 'customer_state'
      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'

      query do
        InvoiceLine.joins(:track, invoice: :customer)
      end
    end
  end




  class TrackSalesMartWithSubFacts < Common
    main_fact do
      has_dimension_level :customer, level: 'country', fact_key: 'customers.country'
      has_dimension_level :customer, level: 'state', fact_key: 'customers.state'
      has_dimension_level :customer, level: 'city', fact_key: 'customers.city', fact_alias: 'customer_city'
      has_dimension_level :customer, level: 'name', fact_key: 'customers.id', fact_alias: 'customer_id'

      has_dimension_level :category, level: 'category', fact_key: 'category'
      has_dimension_level :category, level: 'subcategory', fact_key: 'subcategory'

      has_dimension_level :album, fact_key: 'tracks.album_id'
      has_dimension_level :track, fact_key: 'tracks.id'
      has_dimension_level :genre, fact_key: 'tracks.genre_id'
      has_dimension_level :media_type, fact_key: 'tracks.media_type_id'

      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
      has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'
      has_sum_metric :invoice_count, 'SUM(invoice_counts.invoice_count)'

      query do
        InvoiceLine.joins(:track, invoice: :customer).joins(sub_fact_sql :invoice_counts, on: 'invoice_count')
      end
    end

    sub_fact :invoice_counts do
      propagate :customer, level: 'country', fact_key: 'customers.country'
      has_dimension_level :customer, level: 'state', fact_key: 'customers.state'
      has_dimension_level :customer, level: 'city', fact_key: 'customers.city', fact_alias: 'customer_city'
      has_dimension_level :customer, level: 'name', fact_key: 'customers.id', fact_alias: 'customer_id'

      has_sum_metric :invoice_count, 'COUNT(invoices)'

      query do
        Customer.joins(:invoices)
      end
    end

    sub_fact :invoice_counts, propagate_dimensions: [:customer, :customer_country, :customer_city] do
      Invoice.
          select('customer_id AS customer_id',
                 'customers.country AS customer_country',
                 'customers.customer_city AS customer_city',
                 'COUNT(invoices.id) AS invoice_count').
          joins(:customer).
          group('invoices.customer_id')
    end
  end
end