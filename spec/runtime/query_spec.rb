require 'spec_helper'

describe 'Runtime Queries' do

  before do
    @mart = Class.new(Martyr::Base).tap do |x|
      x.add_query_dimension(:users)
      x.add_time_dimension(:created_at)

      x.add_count_metric :post_count, on: 'post_id'
      x.add_sum_metric :total_comments
      x.main_fact do
        Post.
            select('posts.id AS post_id',
                   'posts.user_id AS user_id',
                   'posts.created_at AS created_at',
                   'count(comments.id) AS total_comments').
            joins(:comments)
      end
    end
  end

  it 'works with basic example' do
    @mart.select(:post_count).group(:user_id)
  end

end

