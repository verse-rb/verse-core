# frozen_string_literal: true

require_relative "in_memory_filtering"

# Very simple repository storing models in memory.
# Used for the specs and testing the whole system.
class InMemoryRepository < Verse::Model::Repository::Base
  class << self
    attr_accessor :data, :id

    def inherited(subclass)
      subclass.instance_variable_set(:@data, [])
      subclass.instance_variable_set(:@id, 0)

      super
    end

    def clear
      @data.clear
      @id = 0
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
        trigger_after_commit
        yield
      ensure
        @in_transaction = false
      end
    end
  end

  def update(id, attributes, scope = scoped(:update))
    target = scope.find{ |record| record[pkey] == id }

    return false unless target

    target.clear
    target.merge!(attributes)

    target
  end

  def create(attributes)
    self.class.id += 1

    id = self.class.id

    row = attributes.merge(id: id)

    self.class.data << row

    id
  end

  def delete(id, scope = scoped(:delete))
    target = scope.find{ |record| record[pkey] == id }

    return false unless target

    self.class.data.delete(target)

    true
  end

  def find_by(
    filters,
    scope: scoped(:read),
    included: [],
    record: self.class.model_class
  )
    filters = encode_filters(filters)
    query = filtering.filter_by(scope, filters, self.class.custom_filters)

    result = query.first

    return if result.nil?

    set = prepare_included(included, [result], record: record)

    record.new(result, include_set: set)
  end

  def index(
    filters,
    scope: scoped(:read),
    included: [],
    page: 1, items_per_page: 1000,
    sort: nil,
    record: self.class.model_class,
    query_count: true # rubocop:disable Lint/UnusedMethodArgument
  )
    filters = encode_filters(filters)
    query = filtering.filter_by(scope, filters, self.class.custom_filters)

    query = query[items_per_page * (page - 1), items_per_page]

    set = prepare_included(included, query, record: record)

    if sort
      count = sort.size

      query = query.sort do |a, b|
        x = 0
        sort.reduce(0) do |sum, (field, direction)|
          field = field.to_sym

          a = a[field.to_sym]
          b = b[field.to_sym]

          result = \
            case
            when a.nil?
              1
            when b.nil?
              -1
            else
              a <=> b
            end

          result = result * (1 << (count-x))
          result = -result if direction == :desc

          x + 1

          sum + result
        end
      end
    end

    metadata = {}
    count = query_count ? query.size : nil
    metadata[:count] = count if count

    Verse::Util::ArrayWithMetadata.new(
      query.map{ |elm| record.new(elm, include_set: set) },
      metadata: metadata
    )
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
