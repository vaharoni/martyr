require 'spec_helper'

describe 'Runtime Queries' do

  describe 'main fact' do

    it 'picks up all grains when no grain can be inferred' do
      sub_cube = MartyrSpec::DegeneratesAndAllLevels.select(:units_sold).execute
      sub_cube.run
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT genres.name AS genres_name,
          media_types.name AS media_types_name,
          customers.country AS customer_country,
          customers.state AS customer_state,
          customers.city AS customer_city,
          customers.id AS customer_id,
          invoices.billing_country AS invoice_country,
          invoices.billing_state AS invoice_state,
          invoices.billing_city AS invoice_city,
          invoices.id AS invoice_id,
          invoice_lines.id AS invoice_line_id,
          tracks.id AS track_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        GROUP BY genres.name,
          media_types.name,
          customers.country,
          customers.state,
          customers.city,
          customers.id,
          invoices.billing_country,
          invoices.billing_state,
          invoices.billing_city,
          invoices.id,
          invoice_lines.id,
          tracks.id
      SQL
    end

    it 'sets the level keys on SELECT and GROUP BY for single degenerate levels that are connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).granulate(media_types: :name, genres: :name).execute
      sub_cube.run
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT media_types.name AS media_types_name,
          genres.name AS genres_name,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        GROUP BY media_types.name,
          genres.name
      SQL
    end

    it 'sets the level keys on SELECT and GROUP BY for all supported hierarchy for multiple degenerate levels that are connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndAllLevels.select(:units_sold).granulate(customers: :city).execute
      sub_cube.run
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT customers.country AS customer_country,
          customers.state AS customer_state,
          customers.city AS customer_city,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        GROUP BY customers.country,
          customers.state,
          customers.city
      SQL
    end

    it 'sets up WHERE for degenerate levels that are connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).
          slice(media_types: {level: :name, with: 'AAC audio file'},
                genres: {level: :name, with: 'Rock'}).execute
      sub_cube.run

      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT media_types.name AS media_types_name,
          genres.name AS genres_name,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "media_types"."name" = 'AAC audio file' AND
           "genres"."name" = 'Rock'
        GROUP BY media_types.name,
          genres.name
      SQL
    end

    it 'adds an extra level to SELECT and GROUP BY for degenerate levels that are connected to the fact when additional grain is provided' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).
          slice(media_types: {level: :name, with: 'AAC audio file'},
                genres: {level: :name, with: 'Rock'}).granulate(customers: :country).execute

      sub_cube.run
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT customers.id AS customer_id,
          media_types.name AS media_types_name,
          genres.name AS genres_name,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "media_types"."name" = 'AAC audio file' AND
           "genres"."name" = 'Rock'
        GROUP BY customers.id,
          media_types.name,
          genres.name
      SQL
    end

    it 'sets up HAVING for metric slices' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold, :amount).granulate(customers: :last_name).slice(:amount, gt: 5).execute
      sub_cube.run
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT customers.id AS customer_id,
          SUM(invoice_lines.quantity) AS units_sold,
          SUM(invoice_lines.unit_price * invoice_lines.quantity) AS amount
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        GROUP BY customers.id
        HAVING SUM(invoice_lines.unit_price * invoice_lines.quantity) > 5
      SQL
    end

    it 'sets up WHERE on keys when slicing on query level that is connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice(albums: {level: :track, with: 'Fast As a Shark'}).execute
      sub_cube.run

      track = Track.find_by(name: 'Fast As a Shark')
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT tracks.id AS track_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "tracks"."id" = #{track.id}
        GROUP BY tracks.id
      SQL
    end

    it 'sets up WHERE on keys when slicing on query level that is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice(albums: {level: :album, with: 'Restless and Wild'}).execute
      sub_cube.run

      track_ids = Album.find_by(title: 'Restless and Wild').track_ids.join(', ')
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT tracks.id AS track_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "tracks"."id" IN (#{track_ids})
        GROUP BY tracks.id
      SQL
    end

    it 'sets up WHERE on keys when slicing on degenerate level that is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice(customers: {level: :country, with: 'USA'}).execute
      sub_cube.run

      customer_ids = Customer.where(country: 'USA').map(&:id).join(', ')
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT customers.id AS customer_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "customers"."id" IN (#{customer_ids})
        GROUP BY customers.id
      SQL
    end

    it 'sets up WHERE on keys when slicing on degenerate level whose query-level-below is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice(invoices: {level: :country, with: 'USA'}).execute
      sub_cube.run

      invoice_line_ids = Invoice.includes(:invoice_lines).where(billing_country: 'USA').flat_map(&:invoice_line_ids).join(', ')
      expect(sub_cube.sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT invoice_lines.id AS invoice_line_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "invoice_lines"."id" IN (#{invoice_line_ids})
        GROUP BY invoice_lines.id
      SQL
    end

    it 'loads the dimension when slicing on query level that is connected to the fact' do
      # sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice(customers: {level: :last_name, with: 'Tremblay'}).execute

    end
  end

  describe 'sub facts' do

  end


end

