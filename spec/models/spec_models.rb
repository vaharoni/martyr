module MartyrSpec
  class Common < Martyr::Cube
    define_dimension :customer do
      degenerate_level :country
      degenerate_level :state
      degenerate_level :city
      query_level :name, -> { Customer.all }
    end

    define_dimension :genre do
      degenerate_level :name
    end

    define_dimension :media_type do
      degenerate_level :name
    end
  end

  # MartyrSpec::TrackSalesMartBasic
  class TrackSalesMartBasic < Common
    with_main_fact do
      has_dimension_level :customer, level: :name, fact_key: 'customers.id', fact_alias: 'customer_id'
      has_dimension_level :genre, level: :name, fact_key: 'genres.name', fact_alias: 'genre_name'
      has_dimension_level :media_type, level: :name, fact_key: 'media_types.name'

      has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
      has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

      query do
        InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
      end
    end
  end
end