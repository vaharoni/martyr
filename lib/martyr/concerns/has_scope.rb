module Martyr
  module HasScope
    extend ActiveSupport::Concern

    included do
      attr_reader :scope
    end

    def update_scope
      @scope = yield(@scope)
    end

    def fetch_scope
      scope.call
    end

    def scope_query
      fetch_scope.try(:arel).try(:to_sql)
    end

    # @example when the scope contains something like:
    #   select('users.id AS user_id')
    #
    # then:
    #   find_select_clause('user_id')
    #   # => 'users.id'
    def find_select_clause(field_name)
      return unless fetch_scope
      res = fetch_scope.select_values.map { |definition| definition.match(/(.*) as #{field_name}/i).try(:[], 1) }.compact.first
      raise "Cannot find field `#{field_name}` in select clause" unless res.present?
      res
    rescue => e
      raise Schema::Error.new(e)
    end

  end
end
