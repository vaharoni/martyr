require 'spec_helper'

describe 'Runtime Queries' do

  describe 'main fact' do
    it 'picks up all grains when no grain can be inferred' do
      sub_cube = MartyrSpec::DegeneratesAndAllLevels.all.build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
          SUM(invoice_lines.quantity) AS units_sold,
          SUM(invoice_lines.unit_price * invoice_lines.quantity) AS amount
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
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).granulate('media_types.name', 'genres.name').build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
      sub_cube = MartyrSpec::DegeneratesAndAllLevels.select(:units_sold).granulate('customers.city').build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
          slice('media_types.name' => {with: 'AAC audio file'}, 'genres.name' => {with: 'Rock'}).
          granulate('media_types.name', 'genres.name').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
          slice('media_types.name' => {with: 'AAC audio file'}, 'genres.name' => {with: 'Rock'}).
          granulate('customers.country', 'media_types.name', 'genres.name').build.sub_cubes.first

      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold, :amount).granulate('customers.last_name').slice(:amount, gt: 5).build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('albums.track' => {with: 'Fast As a Shark'}).granulate('albums.track').build.sub_cubes.first
      sub_cube.test

      track = Track.find_by(name: 'Fast As a Shark')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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

    it 'sets up WHERE on keys when slicing on query level that is connected to the fact with custom label expression' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('invoices.invoice_line' => {with: 'invoice-line-5'}).granulate('invoices.invoice_line').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT invoice_lines.id AS invoice_line_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "invoice_lines"."id" = 5
        GROUP BY invoice_lines.id
      SQL
    end

    it 'sets up WHERE on keys when slicing on query level that is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('albums.album' => {with: 'Restless and Wild'}).granulate('albums.album').build.sub_cubes.first
      sub_cube.test

      track_ids = Album.find_by(title: 'Restless and Wild').track_ids.join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('customers.country' => {with: 'USA'}).granulate('customers.country').build.sub_cubes.first
      sub_cube.test

      customer_ids = Customer.where(country: 'USA').map(&:id).join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('invoices.country' => {with: 'USA'}).granulate('invoices.country').build.sub_cubes.first
      sub_cube.test

      invoice_line_ids = Invoice.includes(:invoice_lines).where(billing_country: 'USA').flat_map(&:invoice_line_ids).join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
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
      # sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice(customers: {level: :last_name, with: 'Tremblay'}).build.sub_cubes.first

    end
  end

  describe 'sub facts' do
    it 'sets up JOIN, SELECT, and GROUP BY correctly for sub facts that expose metrics and dimensions without propagating unsuported dimensions' do
      sub_cube = MartyrSpec::DegeneratesAndCustomersAndSubFacts.
          slice('media_types.name' => {with: 'AAC audio file'}, 'genres.name' => {with: 'Rock'}).granulate('first_invoice.yes_no', 'media_types.name', 'genres.name').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT CASE customer_first_invoices.first_invoice_id WHEN invoices.id THEN 1 ELSE 0 END AS first_invoice_yes_no,
          media_types.name AS media_types_name,
          genres.name AS genres_name,
          SUM(invoice_lines.quantity) AS units_sold,
          SUM(invoice_lines.unit_price * invoice_lines.quantity) AS amount,
          SUM(invoice_counts.invoice_count) AS invoice_count
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
          INNER JOIN (SELECT invoices.customer_id,
                      COUNT(invoices.id) AS invoice_count
                      FROM "invoices"
                      GROUP BY invoices.customer_id) invoice_counts ON invoice_counts.customer_id = customers.id
          INNER JOIN (SELECT invoices.customer_id,
                      MIN(invoices.id) AS first_invoice_id
                      FROM "invoices"
                      GROUP BY invoices.customer_id) customer_first_invoices ON customer_first_invoices.customer_id = customers.id
        WHERE "media_types"."name" = 'AAC audio file' AND
           "genres"."name" = 'Rock'
        GROUP BY CASE customer_first_invoices.first_invoice_id WHEN invoices.id THEN 1 ELSE 0 END,
          media_types.name,
          genres.name
      SQL
    end

    it 'propagates dimension slices to the sub fact when level is supported for both main query and sub query' do
      sub_cube = MartyrSpec::DegeneratesAndCustomersAndSubFacts.select(:units_sold).slice('customers.last_name' => {with: 'Tremblay'}).granulate('customers.last_name').build.sub_cubes.first
      sub_cube.test

      customer_id = Customer.find_by(last_name: 'Tremblay').id
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT customers.country AS customer_country,
          customers.state AS customer_state,
          customers.id AS customer_id,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
          INNER JOIN (SELECT invoices.customer_id,
                      COUNT(invoices.id) AS invoice_count
                      FROM "invoices"
                      WHERE "invoices"."customer_id" = #{customer_id}
                      GROUP BY invoices.customer_id) invoice_counts ON invoice_counts.customer_id = customers.id
          INNER JOIN (SELECT invoices.customer_id,
                      MIN(invoices.id) AS first_invoice_id
                      FROM "invoices"
                      WHERE "invoices"."customer_id" = #{customer_id}
                      GROUP BY invoices.customer_id) customer_first_invoices ON customer_first_invoices.customer_id = customers.id
        WHERE "customers"."id" = #{customer_id}
        GROUP BY customers.country,
          customers.state,
          customers.id
      SQL
    end


    it 'propagates dimension slices to the sub fact when level is supported by main query but not by sub query' do
      sub_cube = MartyrSpec::DegeneratesAndCustomersAndSubFacts.select(:units_sold).slice('customers.country' => {with: 'USA'}).granulate('customers.country').build.sub_cubes.first
      sub_cube.test

      customer_ids = Customer.where(country: 'USA').map(&:id).join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
        SELECT customers.country AS customer_country,
          SUM(invoice_lines.quantity) AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
          INNER JOIN (SELECT invoices.customer_id,
                      COUNT(invoices.id) AS invoice_count
                      FROM "invoices"
                      WHERE "invoices"."customer_id" IN (#{customer_ids})
                      GROUP BY invoices.customer_id) invoice_counts ON invoice_counts.customer_id = customers.id
          INNER JOIN (SELECT invoices.customer_id,
                      MIN(invoices.id) AS first_invoice_id
                      FROM "invoices"
                      WHERE "invoices"."customer_id" IN (#{customer_ids})
                      GROUP BY invoices.customer_id) customer_first_invoices ON customer_first_invoices.customer_id = customers.id
        WHERE "customers"."country" = 'USA'
        GROUP BY customers.country
      SQL
    end
  end


end

