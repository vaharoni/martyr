require 'spec_helper'

describe 'Runtime Queries' do

  describe 'main fact' do

    it 'sets the level keys on SELECT and GROUP BY for single degenerate levels that are connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).granulate('media_types.name', 'genres.name').build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT media_types_name, genres_name, SUM(units_sold) AS units_sold
      FROM (SELECT media_types.name AS media_types_name,
          genres.name AS genres_name,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id") martyr_wrapper
      GROUP BY media_types_name, genres_name
      SQL
    end

    it 'sets the level keys on SELECT and GROUP BY for all supported hierarchy for multiple degenerate levels that are connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndAllLevels.select(:units_sold).granulate('customers.city').build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT customer_country, customer_state, customer_city, SUM(units_sold) AS units_sold
      FROM (SELECT customers.country AS customer_country,
          customers.state AS customer_state,
          customers.city AS customer_city,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id") martyr_wrapper
      GROUP BY customer_country, customer_state, customer_city
      SQL
    end

    it 'sets up WHERE for degenerate levels that are connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).
          slice('media_types.name' => {with: 'AAC audio file'}, 'genres.name' => {with: 'Rock'}).
          granulate('media_types.name', 'genres.name').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT media_types_name, genres_name, SUM(units_sold) AS units_sold
      FROM (SELECT media_types.name AS media_types_name,
          genres.name AS genres_name,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "media_types"."name" = 'AAC audio file' AND
           "genres"."name" = 'Rock') martyr_wrapper
      GROUP BY media_types_name, genres_name
      SQL
    end

    it 'adds an extra level to SELECT and GROUP BY for degenerate levels that are connected to the fact when additional grain is provided' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).
          slice('media_types.name' => {with: 'AAC audio file'}, 'genres.name' => {with: 'Rock'}).
          granulate('customers.country', 'media_types.name', 'genres.name').build.sub_cubes.first

      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT customer_id, media_types_name, genres_name, SUM(units_sold) AS units_sold
      FROM (SELECT customers.id AS customer_id,
          media_types.name AS media_types_name,
          genres.name AS genres_name,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "media_types"."name" = 'AAC audio file' AND
           "genres"."name" = 'Rock') martyr_wrapper
      GROUP BY customer_id, media_types_name, genres_name
      SQL
    end

    it 'sets up HAVING for metric slices' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold, :amount).granulate('customers.last_name').slice(:amount, gt: 5).build.sub_cubes.first
      sub_cube.test
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT customer_id, SUM(units_sold) AS units_sold, SUM(amount) AS amount
      FROM (SELECT customers.id AS customer_id,
          invoice_lines.quantity AS units_sold,
          invoice_lines.unit_price * invoice_lines.quantity AS amount
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id") martyr_wrapper
      WHERE (amount > 5)
      GROUP BY customer_id
      SQL
    end

    it 'sets up where on keys when slicing on query level that is connected to the fact' do
      track = Track.find_by(name: 'Fast As a Shark')
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('albums.track' => {with: track.id}).granulate('albums.track').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT track_id, SUM(units_sold) AS units_sold
      FROM (SELECT tracks.id AS track_id,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "tracks"."id" = #{track.id}) martyr_wrapper
      GROUP BY track_id
      SQL
    end

    it 'sets up WHERE on keys when slicing on query level that is connected to the fact with custom label expression' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('invoices.invoice_line' => {with: 5}).granulate('invoices.invoice_line').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT invoice_line_id, SUM(units_sold) AS units_sold
        FROM (SELECT invoice_lines.id AS invoice_line_id,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "invoice_lines"."id" = 5) martyr_wrapper
      GROUP BY invoice_line_id
      SQL
    end

    it 'sets up WHERE on keys when slicing on query level that is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('albums.album' => {with: 'Restless and Wild'}).granulate('albums.album').build.sub_cubes.first
      sub_cube.test

      track_ids = Album.find_by(title: 'Restless and Wild').track_ids.join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT track_id, SUM(units_sold) AS units_sold
      FROM (SELECT tracks.id AS track_id,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "tracks"."id" IN (#{track_ids})) martyr_wrapper
      GROUP BY track_id
      SQL
    end

    it 'sets up WHERE on keys when slicing on degenerate level that is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('customers.country' => {with: 'USA'}).granulate('customers.country').build.sub_cubes.first
      sub_cube.test

      customer_ids = Customer.where(country: 'USA').map(&:id).join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT customer_id, SUM(units_sold) AS units_sold
      FROM (SELECT customers.id AS customer_id,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "customers"."id" IN (#{customer_ids})) martyr_wrapper
      GROUP BY customer_id
      SQL
    end

    it 'sets up WHERE on keys when slicing on degenerate level whose query-level-below is not connected to the fact' do
      sub_cube = MartyrSpec::DegeneratesAndBottomLevels.select(:units_sold).slice('invoices.country' => {with: 'USA'}).granulate('invoices.country').build.sub_cubes.first
      sub_cube.test

      invoice_line_ids = Invoice.includes(:invoice_lines).where(billing_country: 'USA').flat_map(&:invoice_line_ids).join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT invoice_line_id, SUM(units_sold) AS units_sold
      FROM (SELECT invoice_lines.id AS invoice_line_id,
          invoice_lines.quantity AS units_sold
        FROM "invoice_lines"
          INNER JOIN "tracks" ON "tracks"."id" = "invoice_lines"."track_id"
          INNER JOIN "genres" ON "genres"."id" = "tracks"."genre_id"
          INNER JOIN "media_types" ON "media_types"."id" = "tracks"."media_type_id"
          INNER JOIN "invoices" ON "invoices"."id" = "invoice_lines"."invoice_id"
          INNER JOIN "customers" ON "customers"."id" = "invoices"."customer_id"
        WHERE "invoice_lines"."id" IN (#{invoice_line_ids})) martyr_wrapper
      GROUP BY invoice_line_id
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
      SELECT first_invoice_yes_no, media_types_name, genres_name,
             SUM(units_sold) AS units_sold, SUM(amount) AS amount, SUM(invoice_count) AS invoice_count
      FROM (SELECT CASE customer_first_invoices.first_invoice_id WHEN invoices.id THEN 1 ELSE 0 END AS first_invoice_yes_no,
          media_types.name AS media_types_name,
          genres.name AS genres_name,
          invoice_lines.quantity AS units_sold,
          invoice_lines.unit_price * invoice_lines.quantity AS amount,
          invoice_counts.invoice_count AS invoice_count
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
           "genres"."name" = 'Rock') martyr_wrapper
      GROUP BY first_invoice_yes_no, media_types_name, genres_name
      SQL
    end

    it 'propagates dimension slices to the sub fact when level is supported for both main query and sub query' do
      customer_id = Customer.find_by(last_name: 'Tremblay').id

      sub_cube = MartyrSpec::DegeneratesAndCustomersAndSubFacts.select(:units_sold).slice('customers.last_name' => {with: customer_id}).granulate('customers.last_name').build.sub_cubes.first
      sub_cube.test

      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT customer_country, customer_state, customer_id, SUM(units_sold) AS units_sold
      FROM (SELECT customers.country AS customer_country,
          customers.state AS customer_state,
          customers.id AS customer_id,
          invoice_lines.quantity AS units_sold
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
        WHERE "customers"."id" = #{customer_id}) martyr_wrapper
      GROUP BY customer_country, customer_state, customer_id
      SQL
    end


    it 'propagates dimension slices to the sub fact when level is supported by main query but not by sub query' do
      sub_cube = MartyrSpec::DegeneratesAndCustomersAndSubFacts.select(:units_sold).slice('customers.country' => {with: 'USA'}).granulate('customers.country').build.sub_cubes.first
      sub_cube.test

      customer_ids = Customer.where(country: 'USA').map(&:id).join(', ')
      expect(sub_cube.combined_sql).to eq <<-SQL.gsub(/\s+/, ' ').gsub("\n", '').strip
      SELECT customer_country, SUM(units_sold) AS units_sold
      FROM (SELECT customers.country AS customer_country,
          invoice_lines.quantity AS units_sold
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
        WHERE "customers"."country" = 'USA') martyr_wrapper
      GROUP BY customer_country
      SQL
    end
  end


end
