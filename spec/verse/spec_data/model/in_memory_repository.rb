# frozen_string_literal: true

require_relative "in_memory_filtering"

# Very simple repository storing models in memory.
# Used for the specs and testing the whole system.
class InMemoryRepository < Verse::Model::Repository::Base
  class << self
    attr_accessor :data, :id_sequence

    def inherited(subclass)
      subclass.instance_variable_set(:@data, [])
      subclass.instance_variable_set(:@id_sequence, 0)

      super
    end

    # def id_sequence=(x)
    #   @id_sequence = x
    # end

    # def id_sequence
    #   @id_sequence
    # end

    def clear
      @data.clear
      @id_sequence = 0
    end
  end

  def filtering
    InMemoryFiltering
  end

  def initialize(auth_context)
    super

    @after_commit_blocks = []
  end

  def transaction
    if @in_transaction
      yield
    else
      begin
        @in_transaction = true
        yield
      ensure
        trigger_after_commit
        @in_transaction = false
      end
    end
  end

  def update_impl(id, attributes, scope = scoped(:update))
    target = scope.find{ |record| record[self.class.primary_key] == id }

    return false unless target

    target.merge!(attributes)

    true
  end

  def create_impl(attributes)
    self.class.id_sequence += 1

    id_sequence = self.class.id_sequence

    row = { self.class.primary_key => id_sequence }.merge(attributes)

    self.class.data << row

    id_sequence
  end

  def delete(id, scope = scoped(:delete))
    target = scope.find{ |record| record[self.class.primary_key] == id }

    return false unless target

    self.class.data.delete(target)

    true
  end

  def find_by_impl(
    filters,
    scope: scoped(:read),
    included: [],
    record: self.class.model_class
  )
    filters = encode_filters(filters)
    query = filtering.filter_by(scope, filters, self.class.custom_filters)

    query.first
  end

  def index_impl(
    filters,
    scope:,
    included: [],
    page: 1, items_per_page: 1000,
    sort: nil,
    record: self.class.model_class,
    query_count: true
  )
    query = filtering.filter_by(scope, filters, self.class.custom_filters)
    query = query[items_per_page * (page - 1), items_per_page]
    query ||= [] # in case we are out of bound, it returns nil :(

    if sort
      count = sort.size

      query = query.sort do |a, b|
        x = 0
        sort.reduce(0) do |sum, (field, direction)|
          field = field.to_sym

          a = a[field.to_sym]
          b = b[field.to_sym]

          result = \
            if a.nil?
              1
            elsif b.nil?
              -1
            else
              a <=> b
            end

          result *= (1 << (count - x))
          result = -result if direction == :desc

          sum + result
        end
      end
    end

    metadata = {}
    metadata[:count] = query.size if query_count

    [query, metadata]

  end

  def after_commit(&block)
    raise ArgumentError, "block required" unless block_given?

    if @in_transaction
      @after_commit_blocks << block
    else
      yield
    end
  end

  protected

  def trigger_after_commit
    @after_commit_blocks.each(&:call)
    @after_commit_blocks.clear
  end

  def scoped(action)
    @auth_context.can!(action, self.class.resource) do |scope|
      scope.all? { self.class.data }
      scope.custom? { |id| self.class.data.select{ |h| h[pkey] == id } }
    end
  end
end
