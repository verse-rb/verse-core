# frozen_string_literal: true

require_relative "in_memory_filtering"

class InMemoryRepository < Verse::Model::Repository::Base
  class << self
    attr_accessor :data, :id

    def inherited(subclass)
      subclass.instance_variable_set(:@data, [])
      subclass.instance_variable_set(:@id, 0)
      super
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
    target = scope.find_by{ |record| record[pkey] == id }

    return false unless target

    target.clear
    target.merge!(attributes)

    target
  end

  def create(attributes)
    self.class.id += 1

    row = attributes.merge(id: self.class.id)

    self.class.data[self.class.id] = row
  end

  def delete(id, scope = scoped(:delete))
    target = scope.find_by{ |record| record[pkey] == id }

    return false unless target

    self.class.data.delete(target)

    true
  end

  def find_by(
    filter,
    scope: scoped(:read),
    included: [],
    record: self.class.model_class
  )
    filters = encode_filters(filters)
    query = filtering.filter_by(scope, filters, self.class.custom_filters)

    record = query.first

    set = prepare_included(included, query, record: record)

  end

  def index(
    filters: {},
    scope: scoped(:read),
    included: [],
    page: 1, items_per_page: 1000,
    sort: nil, # rubocop:disable Lint/UnusedMethodArgument
    record: self.class.model_class,
    query_count: true # rubocop:disable Lint/UnusedMethodArgument
  )
    filters = encode_filters(filters)
    query = filtering.filter_by(scope, filters, self.class.custom_filters)

    query = query[items_per_page * (page - 1), items_per_page]

    set = prepare_included(included, query, record: record)

    Verse::Util::ArrayWithMetadata.new(
      result.map{ |elm| record.new(elm, include_set: set) },
      metadata: {
        count: count
      }
    )
  end

  def after_commit(&block)
    @after_commit_blocks << block
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
