# frozen_string_literal: true

require_relative "in_memory_filtering"

class InMemoryRepository < Verse::Model::Repository::Base

  class << self
    attr_accessor :data, :id

    def inherited(subclass)
      subclass.instance_variable_set(:@data, [])
      subclass.instance_variable_set(:@id, 0)
    end
  end


  def filtering
    InMemoryFiltering
  end

  def initialize(auth_context)
    super

    @after_commit_blocks = []
  end

  def transaction(&block)
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
    x = scope.find_by{ |x| x[pkey] == id }

    return false unless x

    x.clear
    x.merge!(attributes)

    x
  end

  def create(attributes)
    self.class.id += 1

    row = attributes.merge(id: self.class.id)

    self.class.data[self.class.id] = row
  end

  def delete(id, scope = scoped(:delete))
    x = scope.find_by{ |x| x[pkey] == id }

    return false unless x

    self.class.data.delete(x)

    true
  end

  def find_by(
    filter,
    scope: scoped(:read),
    included: [],
    record: self.class.model_class
  )
    raise NotImplementedError, "please implement find_by"
  end

  def index(
    filters: {},
    scope: scoped(:read),
    included: [],
    page: 1, items_per_page: 1000,
    sort: nil,
    record: self.class.model_class,
    query_count: true
  )
    filters = encode_filters(filters)
    query = filtering.filter_by(scope, filters, self.class.custom_filters)

    query[iteems_per_page * (page - 1), items_per_page]

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
      if scope.authorized_scopes.to_a.sort != %w[all custom]
        raise "the object #{self.class.resource} doesn't follow default scoping methods.\n" \
              "Please redefined #{self.class}#scoped method"
      end

      scope.all? { @@data }
      scope.custom? { |id| @@data.select{ |h| h[pkey] == id } }
    end
  end

end