# frozen_string_literal: true

require_relative "filtering"
require_relative "../repository/base"

module Verse
  module Model
    module InMemory
      # Very simple and unefficient repository storing models in memory.
      # Used for the specs and testing the whole system.
      class Repository < Repository::Base
        class << self
          attr_accessor :data, :id_sequence

          def inherited(subclass)
            subclass.instance_variable_set(:@data, [])
            subclass.instance_variable_set(:@id_sequence, 0)

            super
          end

          def clear
            @data.clear
            @id_sequence = 0
          end
        end

        def filtering
          Filtering
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

        def update_impl(id, attributes, scope: scoped(:update))
          target = scope.find{ |record| record[self.class.primary_key] == id }

          return false unless target

          target.merge!(attributes)

          true
        end

        def create_impl(attributes)
          attributes = attributes.transform_keys(&:to_sym)
          self.class.id_sequence += 1

          id_sequence = self.class.id_sequence

          row = { self.class.primary_key.to_sym => id_sequence }.merge(attributes)
          pkey = row[self.class.primary_key.to_sym]

          if self.class.data.any?{ |h| h[self.class.primary_key] == pkey }
            raise "duplicate id: #{row[self.class.primary_key.to_sym]} (#{pkey})"
          end

          self.class.data << row

          id_sequence
        end

        def delete(id, scope: scoped(:delete))
          target = scope.find{ |record| record[self.class.primary_key] == id }

          return false unless target

          self.class.data.delete(target)

          true
        end

        def find_by_impl(
          filters,
          scope: scoped(:read)
        )
          filters = encode_filters(filters)
          query = filtering.filter_by(scope, filters, self.class.custom_filters)

          query.first
        end

        def index_impl(
          filters,
          scope:,
          page: 1, items_per_page: 1000,
          sort: nil,
          query_count: false
        )
          query = filtering.filter_by(scope, filters, self.class.custom_filters)
          total_count = query.size

          if sort
            sort = prepare_ordering(sort) if sort.is_a?(String)

            count = sort.size

            query = query.sort do |a, b|
              x = 0
              sort.reduce(0) do |sum, (field, direction)|
                field = field.to_sym

                field_a = a[field.to_sym]
                field_b = b[field.to_sym]

                result = \
                  if field_a.nil?
                    1
                  elsif field_b.nil?
                    -1
                  else
                    field_a <=> field_b
                  end

                result *= (1 << (count - x))
                result = -result if direction == :desc

                x += 1
                sum + result
              end
            end
          end

          query = query[items_per_page * (page - 1), items_per_page]
          query ||= [] # in case we are out of bound, it returns nil :(

          metadata = {}
          metadata[:count] = total_count if query_count

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

        def prepare_ordering(sort)
          if !sort.is_a?(String)
            # :nocov:
            raise ArgumentError, "incorrect ordering parameter type (must be string)"
            # :nocov:
          end

          sort.split(",").map do |x|
            if x[0] == "-"
              [x[1..], :desc]
            else
              [x, :asc]
            end
          end
        end
      end
    end
  end
end
