module MartyrSpec
  class Common < Martyr::Cube
    define_dimension :genres do
      degenerate_level :name, fact_key: 'genres.name', fact_alias: 'genres_name'
    end

    define_dimension :media_types do
      degenerate_level :name, fact_key: 'media_types.name'
    end

    define_dimension :albums do
      query_level :artist, -> { Artist.all }, label_key: 'name', fact_key: 'artists.id', fact_alias: 'artist_id'
      query_level :album, -> { Album.all }, label_key: 'title', fact_key: 'albums.id', fact_alias: 'album_id'
      query_level :track, -> { Track.all }, label_key: 'name', fact_key: 'tracks.id', fact_alias: 'track_id'
    end

    define_dimension :customers do
      degenerate_level :country, fact_key: 'customers.country', fact_alias: 'customer_country'
      degenerate_level :state, fact_key: 'customers.state', fact_alias: 'customer_state'
      degenerate_level :city, fact_key: 'customers.city', fact_alias: 'customer_city'
      query_level :last_name, -> { Customer.all }, fact_key: 'customers.id', fact_alias: 'customer_id'
    end

    define_dimension :invoices do
      degenerate_level :country, query_level_key: :billing_country, fact_key: 'invoices.billing_country', fact_alias: 'invoice_country'
      degenerate_level :state, query_level_key: :billing_state, fact_key: 'invoices.billing_state', fact_alias: 'invoice_state'
      degenerate_level :city, query_level_key: :billing_city, fact_key: 'invoices.billing_city', fact_alias: 'invoice_city'
      query_level :invoice, -> { Invoice.all }, label_key: 'id', fact_key: 'invoices.id', fact_alias: 'invoice_id'
      query_level :invoice_line, -> { InvoiceLine.all }, label_key: 'id', fact_key: 'invoice_lines.id', fact_alias: 'invoice_line_id'
    end
  end

  class DegeneratesAndBottomLevels < Common
    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # Bottom levels
    has_dimension_level :customers, :last_name
    has_dimension_level :invoices, :invoice_line
    has_dimension_level :albums, :track

    has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
    has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndAllLevels < Common
    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    has_dimension_level :customers, :last_name
    has_dimension_level :customers, :city
    has_dimension_level :customers, :state
    has_dimension_level :customers, :country
                                   
    has_dimension_level :invoices, :invoice_line
    has_dimension_level :invoices, :invoice
    has_dimension_level :invoices, :city
    has_dimension_level :invoices, :state
    has_dimension_level :invoices, :country

    # Album is not connected to the fact query so only the bottom level is available
    has_dimension_level :albums, :track

    has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
    has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndHighLevels < Common
    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # High levels - degenerate
    has_dimension_level :customers, :state
    has_dimension_level :customers, :country

    # High level - query without degenerates
    has_dimension_level :invoices, :invoice

    has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
    has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  # class DegeneratesAndBottomLevelsWithAlbumsAndSubFacts < Common
  #   define_dimension :first_invoice do
  #     degenerate_level :yes_no
  #   end
  #
  #   # Degenerates
  #   has_dimension_level :genres, :name
  #   has_dimension_level :media_types, :name
  #
  #   has_dimension_level :customers, :last_name
  #   has_dimension_level :customers, :state
  #   has_dimension_level :customers, :country
  #
  #   has_dimension_level :invoices, :invoice_line
  #
  #   has_dimension_level :albums, :artist
  #
  #   has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
  #   has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'
  #
  #   # Sub facts
  #   has_dimension_level :first_invoice, :yes_no,
  #                       fact_key: 'COALESCE(customer_first_invoices.first_invoice_yes_no, 0)'
  #
  #   main_query do
  #     InvoiceLine.joins(track: [{album: :artist}, :genre, :media_type], invoice: :customer)
  #   end
  #
  #   sub_query :invoice_counts do
  #     joins_with 'INNER JOIN', on: "#{name}.customer_id = customers.id"
  #     propagates_dimension_level :customers, :last_name
  #
  #     Invoice.
  #         select('invoices.customer_id',
  #                'COUNT(invoice.id) AS invoice_line_count').
  #         group('invoices.customer_id')
  #   end
  #
  #   sub_query :customer_first_invoices do
  #     joins_with 'LEFT OUTER JOIN', on: "#{name}.first_invoice_line_id = invoice_lines.id"
  #
  #     InvoiceLine.
  #         select('MIN(invoice_lines.id) AS first_invoice_line_id',
  #                '1 AS first_invoice_yes_no').
  #         group('invoices_lines.id')
  #   end
  # end
end