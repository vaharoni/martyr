module MartyrSpec
  class Common < Martyr::Cube
    define_dimension :genres do
      degenerate_level :name, fact_key: 'genres.name', fact_alias: 'genres_name'
    end

    define_dimension :media_types do
      degenerate_level :name, fact_key: 'media_types.name'
    end

    define_dimension :albums do
      query_level :artist, -> { Artist.all }, label_key: 'name'
      query_level :album, -> { Album.all }, label_key: 'title'
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
    with_main_fact do
      # Degenerates
      has_dimension_level :genres, level: :name
      has_dimension_level :media_types, level: :name

      # Bottom levels
      has_dimension_level :customers, level: :last_name
      has_dimension_level :invoices, level: :invoice_line
      has_dimension_level :albums, level: :track

      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
      has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

      query do
        InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
      end
    end
  end

  class DegeneratesAndAllLevels < Common
    with_main_fact do
      # Degenerates
      has_dimension_level :genres, level: :name
      has_dimension_level :media_types, level: :name

      has_dimension_level :customers, level: :last_name
      has_dimension_level :customers, level: :city
      has_dimension_level :customers, level: :state
      has_dimension_level :customers, level: :country

      has_dimension_level :invoices, level: :invoice_line
      has_dimension_level :invoices, level: :invoice
      has_dimension_level :invoices, level: :city
      has_dimension_level :invoices, level: :state
      has_dimension_level :invoices, level: :country

      # Album is not connected to the fact query so only the bottom level is available
      has_dimension_level :albums, level: :track

      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
      has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

      query do
        InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
      end
    end
  end

  class DegeneratesAndHighLevels < Common
    with_main_fact do
      # Degenerates
      has_dimension_level :genres, level: :name
      has_dimension_level :media_types, level: :name

      # High levels - degenerate
      has_dimension_level :customers, level: :state
      has_dimension_level :customers, level: :country

      # High level - query without degenerates
      has_dimension_level :invoices, level: :invoice

      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
      has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

      query do
        InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
      end
    end
  end

  # Degenerates:
  #   genres, media_types
  #
  # Skipped levels:
  #   customers - last_name, state, country (skipped city)
  #   invoices - invoice_lines, state, country (skipped invoice and city)
  #
  # class DegeneratesAndSkipLevels < Common
  #   with_main_fact do
  #     # Degenerates
  #     has_dimension_level :genres, level: :name
  #     has_dimension_level :media_types, level: :name
  #
  #     # Skipped level - city
  #     has_dimension_level :customers, level: :last_name
  #     has_dimension_level :customers, level: :state
  #     has_dimension_level :customers, level: :country
  #
  #     # Skipped levels - invoices and city
  #     has_dimension_level :invoices, level: :invoice_line
  #     has_dimension_level :invoices, level: :state
  #     has_dimension_level :invoices, level: :country
  #
  #     has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
  #     has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'
  #
  #     query do
  #       InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
  #     end
  #   end
  # end

end