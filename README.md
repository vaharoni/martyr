# Martyr

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/martyr`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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
