require 'spec_helper'

describe 'Runtime Queries' do

  before do
    @parent = Class.new(Martyr::Cube).tap do |x|
      x.add_query_dimension :customer
      x.add_query_dimension :album
      x.add_query_dimension :track
      x.add_query_dimension :genre
      x.add_query_dimension :media_type
    end

    @mart = Class.new(@parent).tap do |x|
      x.add_degenerate_dimension :customer_country, 'customers.country'
      x.add_degenerate_dimension :customer_city, 'customers.city'
      x.use_shared_dimension :customer, 'customers.id'

      x.use_shared_dimension :album, 'tracks.album_id'
      x.use_shared_dimension :track, 'tracks.id'
      x.use_shared_dimension :genre, 'tracks.genre_id'
      x.use_shared_dimension :media_type, 'tracks.media_type_id'

      x.add_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
      x.add_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

      x.main_fact do
        InvoiceLine.joins(:track, invoice: :customer)
      end
    end
  end

  it 'sets up SELECT clause correctly for metrics and degenerate & query dimensions' do
    sub_cube = @mart.select(:units_sold, :amount).group(:media_type, :genre, :customer, :customer_country).execute
    expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT tracks.media_type_id AS media_type_id,
             tracks.genre_id AS genre_id,
             customers.id AS customer_id,
             customers.country AS customer_country,
             SUM(invoice_lines.quantity) AS units_sold,
             SUM(invoice_lines.unit_price * invoice_lines.quantity) AS amount
      FROM "invoice_lines"
        INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
        INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
        INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
      GROUP BY tracks.media_type_id, tracks.genre_id, customers.id, customers.country
    SQL
  end

  it 'sets up WHERE clause correctly for degenerate dimension slice' do
    sub_cube = @mart.select(:units_sold).group(:media_type, :genre).slice(:customer_country, with: 'USA').execute
    expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT tracks.media_type_id AS media_type_id, 
             tracks.genre_id AS genre_id, 
             SUM(invoice_lines.quantity) AS units_sold 
      FROM "invoice_lines" 
        INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
        INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
        INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
      WHERE "customers"."country" = 'USA'
      GROUP BY tracks.media_type_id, tracks.genre_id
    SQL
  end

  it 'sets up WHERE clause correctly for query dimension slice' do
    sub_cube = @mart.select(:units_sold).group(:media_type, :genre).slice(:customer, with: 1).execute
    expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT tracks.media_type_id AS media_type_id,
             tracks.genre_id AS genre_id,
             SUM(invoice_lines.quantity) AS units_sold
      FROM "invoice_lines"
        INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
        INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
        INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
      WHERE "customers"."id" = 1
      GROUP BY tracks.media_type_id, tracks.genre_id
    SQL
  end

  it 'sets up HAVING clause correctly for metric slice' do
    sub_cube = @mart.select(:units_sold).group(:media_type, :genre).slice(:amount, gt: 0).execute
    expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT tracks.media_type_id AS media_type_id,
             tracks.genre_id AS genre_id,
             SUM(invoice_lines.quantity) AS units_sold
      FROM "invoice_lines"
        INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
        INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
        INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
      GROUP BY tracks.media_type_id, tracks.genre_id
      HAVING SUM(invoice_lines.unit_price * invoice_lines.quantity) > 0
    SQL
  end

end

