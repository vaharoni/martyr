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
  #   Optional dimension value for one (the lower) level.
  # Tuple: (M1, D1 => {level: 2, with: 'D1.2.5'})
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
  #  About degenerate levels:
  #   1. As soon as one level is considered degenerate, all levels above it must be degenerate.
  #   2. If degenerate level is directly connected to the fact, it is always sliced and grouped by directly on the fact.
  #   3. If all levels are degenerate, then all of the levels must be connected directly to the fact.
  #   4. If degenerate level is above query level, it must provide custom ways to perform WHERE on the next query level
  #
  #
  #      Level Type       Connected to Fact?      Operation        Example        Strategy
  #      Query             Yes                     WHERE            A1            Separate dimension query, WHERE on IDs
  #      Query             Yes                     GROUP BY         A1            Group by on the column on the fact
  #      Query             No                      WHERE            A4            Separate dimension query with :includes, WHERE on IDs
  #      Query             No                      GROUP BY         A4            ==> MAYBE I SHOULD DO A MEMORY SLICE HERE
  #
  #      Degenerate        Yes                     WHERE            A1            No dimension query - straight to the fact
  #      Degenerate        Yes                     GROUP BY         A1            Group by on the column on the fact
  #      Degenerate        No                      WHERE            A4
  #      Degenerate        No                      GROUP BY         A4
  #
  #
  #
  #
  # Use cases, assuming D1.1, D1.2 where D1.1 is leaf level of D1:
  #
  #  A. Cube #1, with has_level D1.1 only:
  #       Slice               Group Statement     Result
  #  (1)  D1.1                  D1.1              GROUP BY on D1.1, WHERE on D1.1
  #  (2)  D1.1                  D1.2              Group will automatically expand to include D1.1. Equivalent to Group D1.1, D1.2
  #  (3)  D1.2                  D1.1              Group will automatically expand to include D1.2. Equivalent to Group D1.1, D1.2
  #  (4)* D1.2                  D1.2              JOINS D1.2, GROUP BY D1.2, WHERE on D1.2
  #  (5)  D1.1                  D1.1, D1.2        GROUP BY on D1.1, WHERE on D1.1. Note that D1.2 is not joined in or used.
  #  (6)* D1.2                  D1.1, D1.2        JOINS D1.2, GROUP BY D1.1 & D1.2, WHERE on D1.2.
  #
  #  B. Cube #2, with has_level D1.2 only:
  #       Slice               Group Statement     Result
  #  (1)  D1.1                  D1.1              Null results. D1.1 is not defined in the cube.
  #  (2)  D1.1                  D1.2              Null results. D1.1 is not defined in the cube.
  #  (3)  D1.2                  D1.1              D1.1 will be removed from group, D1.2 added. Equivalent to Group D1.2.
  #  (4)  D1.2                  D1.2              WHERE on D1.2
  #  (5)  D1.1                  D1.1, D1.2        Null results. D1.1 is not defined in the cube.
  #  (6)  D1.2                  D1.1, D1.2        D1.1 will be removed from group. Equivalent to Group D1.2.
  #
  #  C. Cube #3, with has_level D1.1 and D1.2:
  #       Slice               Group Statement     Result
  #  (1)  D1.1                  D1.1              GROUP BY on D1.1, WHERE on D1.1
  #  (2)  D1.1                  D1.2              Group will automatically expand to include D1.1. Equivalent to Group D1.1, D1.2
  #  (3)  D1.2                  D1.1              Group will automatically expand to include D1.2. Equivalent to Group D1.1, D1.2
  #  (4)  D1.2                  D1.2              WHERE on D1.2
  #  (5)  D1.1                  D1.1, D1.2        GROUP BY on D1.1, WHERE on D1.1. D1.2 is not used.
  #  (6)  D1.2                  D1.1, D1.2        GROUP BY on D1.1 & D1.2, WHERE on D1.2.
  #
  # A few things to note:
  #   - `slice` is setting the agenda. `group` will always expand to include the `slice`.
  #   - The only good reason behind `group` is to include a +lower level+ than the `slice`.
  #   - Calculated metrics, selected using `select` expand the `group` without affecting `slice`.
  #   - This means that in most cases `group` is not needed at all.
  #
  # Cases A4 and A6 above mean we need dimension levels to know how to do three things:
  #   1. Joined into the fact statement
  #   2. Add themselves to the WHERE clause
  #   3. Add themselves to the GROUP BY clause
  #

  #
  # Advantage:
  #   Knowing a cell coordinates mean that we can easily traverse between similar cubes with shared dimensions.
  #
  #   This is ideal for dashboard and business intelligence applications because:
  #   1. Cells can be drilled down on by adding a new dimension or expanding a level.
  #


  # Rules:
  # - Dimensions must connect to the fact table from the lowest level. There is no mid-level connection.
  # - We need to allow drill-through, so that facts.first.customer will yield a Customer object
  #


  # 1. Sub cube is with D1.
  # 1. Dimension has level defined on the fact -- it will be used directly from there when a slice
  # 2. Dimenion is sliced



  class Schema1 < Martyr::Cube
    # Query dimension - with scope.
    # This means that as long as the lowest level is defined with `has_dimension_level`, the other levels can be inferred
    # in memory as it assumes Customer has the methods #country, #state, #city and #name.
    define_query_dimension :customer, -> { Customer.all }, title: 'Customer' do
      level :country, primary_key: 'customer_country', label_key: 'customer_country', title: 'Country'
      level :state, primary_key: 'customer_state', label_key: 'customer_state', title: 'State'
      level :name, primary_key: 'id', label_key: 'customer_name', fact_key: 'customer_id', title: 'Name'
    end

    define_query_dimension :album, title: 'Album' do
      level :name, primary_key: 'id', label_key: 'name', title: 'Album name'
    end

    define_degenerate_dimension :category, title: 'Category / Subcategory' do
      level :category, title: 'Category'
      level :sub_category, title: 'Sub category'
    end
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
      has_dimension_level :customer, level: 'country', fact_key: 'customers.country'
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