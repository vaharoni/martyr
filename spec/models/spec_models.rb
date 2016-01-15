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
      query_level :invoice, -> { Invoice.all }, label_expression: "'invoice-' || invoices.id", fact_key: 'invoices.id', fact_alias: 'invoice_id'
      query_level :invoice_line, -> { InvoiceLine.all }, label_expression: "'invoice-line-' || invoice_lines.id", fact_key: 'invoice_lines.id', fact_alias: 'invoice_line_id'
    end

    define_dimension :playlists do
      query_level :name, -> { Playlist.all }, label_key: 'name'
    end
  end

  class DegeneratesAndBottomLevels < Common
    set_cube_name :cube

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # Bottom levels
    has_dimension_level :customers, :last_name
    has_dimension_level :invoices, :invoice_line
    has_dimension_level :albums, :track

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    has_count_distinct_metric :customer_count, level: 'customers.last_name'

    has_custom_metric :commission, ->(fact) { (fact.amount * 0.3) }, depends_on: 'amount'

    # If one rollup is dependent on the other, make sure they are ordered correctly
    has_custom_rollup :avg_transaction, ->(element) { (element.amount.to_f / element.units_sold).round(2) }, depends_on: %w(amount units_sold)
    has_custom_rollup :usa_amount, ->(element) { element.locate('customers.country', with: 'USA').amount }, depends_on: 'amount', fact_grain: 'customers.country'
    has_custom_rollup :cross_country_avg_transaction, ->(element) { element.locate(reset: 'customers.*').avg_transaction }, depends_on: 'avg_transaction'
    has_custom_rollup :usa_avg_transaction, ->(element) { element.locate('customers.country', with: 'USA').avg_transaction }, depends_on: 'avg_transaction', fact_grain: 'customers.country'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndAllLevels < Common
    set_cube_name :cube

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

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndHighLevels < Common
    set_cube_name :cube

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # High levels - degenerate
    has_dimension_level :customers, :state
    has_dimension_level :customers, :country

    # High level - query without degenerates
    has_dimension_level :invoices, :invoice

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndHoleAndLowLevel < Common
    set_cube_name :cube

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # Hole within customers dimension - skips city. Below hole there is a query dimension
    has_dimension_level :customers, :country
    has_dimension_level :customers, :state
    has_dimension_level :customers, :last_name

    # Hole within invoices dimension - skips state. Below hole there is a degenerate dimension.
    has_dimension_level :invoices, :country
    has_dimension_level :invoices, :city
    has_dimension_level :invoices, :invoice
    has_dimension_level :invoices, :invoice_line

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndNoQueryLevel < Common
    set_cube_name :cube

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # Skip high level country
    has_dimension_level :customers, :state
    has_dimension_level :customers, :city

    # With hole - skip state
    has_dimension_level :invoices, :country
    has_dimension_level :invoices, :city

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class NoHighLevels < Common
    set_cube_name :cube

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # Skip high level country
    has_dimension_level :customers, :state
    has_dimension_level :customers, :city
    has_dimension_level :customers, :last_name

    # With hole - skip state
    has_dimension_level :invoices, :city
    has_dimension_level :invoices, :invoice
    has_dimension_level :invoices, :invoice_line

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class DegeneratesAndCustomersAndSubFacts < Common
    set_cube_name :cube

    define_dimension :first_invoice do
      degenerate_level :yes_no
    end

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    has_dimension_level :customers, :last_name
    has_dimension_level :customers, :state
    has_dimension_level :customers, :country

    has_dimension_level :invoices, :invoice_line

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    # Sub facts
    has_sum_metric :invoice_count, 'invoice_counts.invoice_count'
    has_dimension_level :first_invoice, :yes_no,
      fact_key: 'CASE customer_first_invoices.first_invoice_id WHEN invoices.id THEN 1 ELSE 0 END'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end

    sub_query :invoice_counts do
      joins_with 'INNER JOIN', on: "#{name}.customer_id = customers.id"
      has_dimension_level :customers, :last_name, fact_key: 'invoices.customer_id'

      Invoice.
        select('invoices.customer_id',
          'COUNT(invoices.id) AS invoice_count').
        group('invoices.customer_id')
    end

    sub_query :customer_first_invoices do
      joins_with 'INNER JOIN', on: "#{name}.customer_id = customers.id"
      has_dimension_level :customers, :last_name, fact_key: 'invoices.customer_id'

      Invoice.
        select('invoices.customer_id',
          'MIN(invoices.id) AS first_invoice_id').
        group('invoices.customer_id')
    end
  end

  # = Virtual Cubes

  class InvoiceCube < Common
    set_cube_name :invoices_cube

    # Degenerates
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    # Bottom levels
    has_dimension_level :customers, :last_name
    has_dimension_level :invoices, :invoice_line
    has_dimension_level :albums, :track

    has_sum_metric :units_sold, 'invoice_lines.quantity'
    has_sum_metric :amount, 'invoice_lines.unit_price * invoice_lines.quantity'

    main_query do
      InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
    end
  end

  class PlaylistCube < Common
    set_cube_name :playlists_cube

    has_dimension_level :playlists, :name, fact_key: 'playlists.id', fact_alias: 'playlist_id'
    has_dimension_level :genres, :name
    has_dimension_level :media_types, :name

    has_sum_metric :tracks_count, 'COUNT(playlists.id)'

    main_query do
      Playlist.joins(tracks: [:genre, :media_type])
    end
  end

  class VirtualCubeTest < Martyr::VirtualCube
    use_cube 'MartyrSpec::PlaylistCube'
    use_cube 'MartyrSpec::InvoiceCube'
  end

end
