require 'active_record'

class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :comment
end


class Fixtures
  def self.setup
    connect
    create_tables
    create_demo_data
  end

  def self.connect
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', database: ':memory:'
  end

  def self.create_tables
    {
      'users' => 'name VARCHAR(255)',
      'posts' => 'user_id INTEGER, title VARCHAR(255), rating VARCHAR(32), text VARCHAR(255)',
      'comments' => 'post_id INTEGER, user_id INTEGER, comment VARCHAR(255)'
    }.each do |table_name, columns_as_sql_string|
      ActiveRecord::Base.connection.execute "CREATE TABLE #{table_name} " +
                                                "(id INTEGER NOT NULL PRIMARY KEY, #{columns_as_sql_string}, " +
                                                "created_at DATETIME, updated_at DATETIME)"
    end
  end

  def self.create_demo_data
    a, b, c, d, e, f, h = %w(Alice Bob Carrie Dana Erik Frank Hugh).map {|name| User.create! name: name}

    Post.create! user: a, title: 'Alice post 1', rating: :a, text: 'Post text 1'
    Post.create! user: a, title: 'Alice post 2', rating: :a, text: 'Post text 2'
  end

end