# frozen_string_literal: true

module InMemoryFiltering
  OPERATIONS = {
    lt: ->(col, column, value) { col.select{ |x| x[column] < value } },
    lte: ->(col, column, value) { col.select{ |x| x[column] <= value } },
    gt: ->(col, column, value) { col.select{ |x| x[column] > value } },
    gte: ->(col, column, value) { col.select{ |x| x[column] >= value } },
    eq: ->(col, column, value) {
      case value
      when Array
        if value.empty?
          []
        else
          col.select{ |x| value.include?(x[column]) }
        end
      else
        col.select{ |x| x[column] == value }
      end
    },
    neq: ->(col, column, value) { col.reject{ |x| x[column] == value } },
    prefix: ->(col, column, value) { col.select{ |x| x[column].to_s.start_with?(value) } },
    in: ->(col, column, value) { col.select{ |x| value.include?(x[column]) } },
    match: ->(col, column, value) { col.select{ |x| x[column].to_s =~ regexp(value) } },
    contains: ->(col, column, value) {
      case value
      when Array
        if value.empty?
          []
        else
          col.select{ |x| value.all?{ |v| x[column].include?(v) } }
        end
      when Hash
        col.select{ |x| x[column].include?(value) }
      else
        col.select{ |x| x[column].include?(value) }
      end
    },
  }.freeze

  def self.expect_array?(operator)
    %i[eq in contains].include?(operator.to_sym)
  end

  def self.filter_by(collection, filtering_parameters, custom_filters)
    return collection if filtering_parameters.nil? || filtering_parameters.empty?

    collection = collection.lazy

    filtering_parameters.each do |key, value|
      custom_filter = custom_filters && custom_filters[key.to_s]

      if custom_filter
        collection = custom_filter.call(collection, value)
        next
      end

      column_name, operation = key.to_s.split(/__([a-z]+)$/)

      operation ||= "eq"

      collection = OPERATIONS.fetch(operation.to_sym).call(collection, column_name.to_sym, value)
    end

    collection.to_a
  end
end
