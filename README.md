# Martyr
  A multi-dimensional semantic layer on top of ActiveRecord that allows running pivot table queries and rendering
  them as CSV, HTML, or KickChart-ready hashes. Supports time dimensions, cohort analysis, custom rollups, and drilling
  through to the underlying ActiveRecord objects.

  Designed predominantly to allow staff members and site owners to slice and dice data and easily produce reports.

  Warning:
  This gem is not production ready.

  More to come...

## The problem
  The following simple queries demonstrate a core issue with relational data:

```ruby
# Fetch count of all posts that were created 3 days ago
Post.where('created_at > ?', 3.days.ago)

# Fetch count of all posts that were created by the author whose email is me@domain.com
Post.joins(:author).where('authors.email' => 'me@domain.com')
```
   These two queries represent similar requests from the perspective of a human user. However, fulfilling these requests
   requires knowledge about the structure of the database. This limits the  ability to provide "free form" slicing and dicing of data.

   Compare these queries with Martyr standard query interface:
```ruby
# Fetch count of all posts that were created 3 days ago
PostCube.slice('post.created_at', gt: 3.days.ago)

# Fetch count of all posts that were created by the author whose email is me@domain.com
PostCube.slice('author.email', with: 'me@domain.com')

# As a compound hash format:
PostCube.slice('author.email' => {with: 'me@domain.com'}, 'post.created_at' => {gt: 3.days.ago})
```
  The last example demonstrates an important aspect of Martyr. A simple standard hash - which can be easily
  serialized over HTTP requests - represents a slice of data that can be further manipulated. This means you can have
  one standard controller action for displaying tables and graphs of any data you like.

  Martyr keeps track of the slice of every element you query:

```ruby
pivot_table = PostCube.slice('post.created_at', gt: 3.days.ago).pivot.on_columns('post_count').on_rows('authors.email')
first_row = pivot_table.rows.first
cell = first_row.cell_at['post_count']
cell.coordinates
# => { 'metric' => 'posts_cube.post_count', 'post.created_at' => {gt: 3.days.ago}, 'authors.email' => 'first_row@domain.com'}
```

  So an ERB partial that renders this cell as a link to another report - number of comments per post-type for that particular author and created_at constraints - may look like this:
```ERB
<% data = Base64.urlsafe_encode64 {current_slice: cell.coordinates,
                                   on_rows: ['post.type'],
                                   on_columns: ['comment.type'],
                                   view: 'my_drill_down_report' }.to_json %>

<%= link_to cell.value, standard_report_action_path(data: data) %>
```

  And the standard (non-secure) controller action can be as simple as:
```ruby
def standard_drill_down
  hash = JSON.parse(Base64.urlsafe_decode64(params[:data]}
  query = PostCube.slice(hash['current_slice']).granulate(hash['on_rows'] + hash['on_columns'])
  @pivot_table = query.pivot.on_columns(hash['on_columns']).on_rows(hash['on_rows'])
  render hash['view']
end
```


The examples that follow refer to the open source Chinook database schema.

## Semantic layer DSL

```ruby
class SharedDimensions < Martyr::Cube
  define_dimension :genres do
    degenerate_level :name
  end

  define_dimension :media_types do
    degenerate_level :name
  end

  define_dimension :customers do
    degenerate_level :country
    degenerate_level :state
    degenerate_level :city
    query_level :last_name, -> { Customer.all }, fact_key: 'customers.id'
  end
end

class MyCube < SharedDimensions
  has_dimension_level :genres, :name
  has_dimension_level :media_types, :name
  has_dimension_level :customers, :last_name

  has_sum_metric :units_sold, 'SUM(invoice_lines.quantity)'
  has_sum_metric :amount, 'SUM(invoice_lines.unit_price * invoice_lines.quantity)'

  has_custom_metric :commission, ->(fact) { (fact['amount'] * 0.3) }

  has_custom_rollup :avg_transaction, ->(fact_set) { fact_set['amount'] / fact_set['units_sold'] }
  has_custom_rollup :usa_amount, ->(fact_set) { fact_set.locate('customers.country', with: 'USA')['amount'] }
  has_custom_rollup :cross_country_avg_transaction, ->(fact_set) { fact_set.locate(reset: 'customers.*')['avg_transaction'] }
  has_custom_rollup :usa_avg_transaction, ->(fact_set) { fact_set.locate('customers.country', with: 'USA')['avg_transaction'] }

  main_query do
    InvoiceLine.joins(track: [:genre, :media_type], invoice: :customer)
  end
end
```

## Query interface

Use `#granulate` to perform group by:
```ruby
q = MyCube.granulate('genres.name', 'customers.city').pivot.on_columns(:metrics).on_rows('genres.name', 'customers.city')
q.to_csv
q.to_chart      # => Kick chart format
```

Use `#select` to choose metrics and `#slice` to perform where:
```ruby
MyCube.select('units_sold', 'amount').
       granulate('genres.name', 'customers.city').
       slice('customers.country', with: 'USA').
       pivot.on_columns(:metrics).on_rows('genres.name', 'customers.city').to_csv
```

The same thing can be done in stages:
```ruby
query = MyCube.select('units_sold', 'amount').
                  granulate('genres.name', 'customers.city').
                  slice('customers.country', with: 'USA').build

query.pivot.on_columns(:metrics).on_rows('genres.name', 'customers.city').to_csv
```

Which allows further slicing in memory - in the same standard way - rather than in SQL:
```ruby
query = MyCube.select('units_sold', 'amount').granulate('genres.name', 'customers.city').build
usa_slice = query.slice('customers.country', with: 'USA')
france_slice = query.slice('customers.country', with: 'France')

# One DB query, two reports
usa_slice.pivot.on_columns('genres.name').on_rows('customers.city').in_cells('units_sold').to_csv
france_slice.pivot.on_columns('genres.name').on_rows(:metrics).to_csv
```

## Virtual cubes DSL

Virtual cubes allow referring to two or more cubes, each with different granularity, on the same report.
```ruby
class MyOtherCube < SharedDimensions
  define_dimension :playlists do
    query_level :name, -> { Playlist.all }, label_key: 'name'
  end

  has_dimension_level :genres, :name
  has_dimension_level :media_types, :name
  has_dimension_level :playlists, :name, fact_key: 'playlists.id'

  has_sum_metric :tracks_count, 'COUNT(playlists.id)'

  main_query do
    Playlist.joins(tracks: [:genre, :media_type])
  end
end

class MyVirtualCube < Martyr::VirtualCube
  use_cube 'MyCube'
  use_cube 'MyOtherCube'
end
```

## Using virtual cubes

Usage is the same as regular cubes.
```ruby
query = MyVirtualCube.granulate('genres.name').on_columns('genres.name').on_rows('my_other_cube.tracks_count', 'my_cube.units_sold')
```







## Installation

Add this line to your application's Gemfile:

```ruby
gem 'martyr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install martyr

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/martyr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


Limitations:
- If you want to connect degenerate levels directly to the fact, make sure that they are unique across the entire
  dimension.

  For example, consider a simple dimension 'customers.country', 'customers.city', 'customers.name', and that
  'customers.name' is a query level, and the other levels are degenerates.

  Problem:
    If the cube connects with 'customers.city', the grain is 'customers.city', and the slice is 'customers.city' => 'Dover',
    When you run `facts.first['customers.country']` you may receive either US or UK (if Dover appears once for each in
    the dimension).

    The reason is that Martyr needs a query level in order to resolve higher degenerate levels that do not connect to
    the fact. To do that, it maintains one "representative" 'customers.name' record for each degenerate 'customers.city'
    value. It then asks this representative to fetch its 'customers.country', which could be either US or UK, depending
    on the randomly chosen representative.

  Workaround 1:
    Connect 'customers.country' to the fact.
    Martyr always prefer to take degenerates from the facts if they are available.

  Workaround 2:
    Connect 'customers.name' to the cube and add it to the grain.
    Martyr will prefer to use the query level 'customers.name' when resolving for 'customers.country'.

  Reproduce:
    c = Customer.create first_name: 'Amit', last_name: 'Aharoni', city: 'Paris', country: 'Hungary', email: 'amit.sites@gmail.com'
    i = Invoice.create customer_id: c.id, invoice_date: Time.now, billing_country: 'Hungary', billing_city: 'Paris', total: 100
    InvoiceLine.create invoice_id: i.id, track_id: 1, unit_price: 1, quantity: 100

    sub_cube1 = MartyrSpec::DegeneratesAndNoQueryLevel.granulate('customers.city', 'genres.name').slice('customers.city', with: 'Paris').build.sub_cubes.first
    sub_cube2 =    MartyrSpec::DegeneratesAndAllLevels.granulate('customers.city', 'genres.name').slice('customers.city', with: 'Paris').build.sub_cubes.first
    sub_cube3 = MartyrSpec::NoHighLevels.granulate('customers.last_name', 'genres.name').slice('customers.city', with: 'Paris').build.sub_cubes.first

    sub_cube1.elements(levels: ['customers.city', 'customers.country']).count
    # => 1
    sub_cube2.elements(levels: ['customers.city', 'customers.country']).count
    # => 2
    sub_cube3.elements(levels: ['customers.city', 'customers.country']).count
    # => 2
