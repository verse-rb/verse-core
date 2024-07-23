# frozen_string_literal: true

require_relative "./class_methods"

module Verse
  module Model
    module Repository
      class Base
        extend ClassMethods
        @dispatch_event_mode = :on_commit
        @dispatch_events = []

        attr_reader :auth_context, :metadata

        def initialize(auth_context)
          @auth_context = auth_context
          @metadata = {}
        end

        def filtering
          # :nocov:
          raise NotImplementedError, "please implement filtering algorithm" # :nocov:
          # :nocov:
        end

        def transaction(&block)
          # :nocov:
          raise NotImplementedError, "please implement transaction"
          # :nocov:
        end

        def after_commit(&block)
          # :nocov:
          raise NotImplementedError, "please implement after_commit"
          # :nocov:
        end

        def dispatch_event(&block)
          return if @disable_event

          case Verse::Event::Dispatcher.event_mode
          when :immediate
            block.call
          when :on_commit
            after_commit(&block)
          when :manual
            Verse::Event::Dispatcher.register_event(&block)
          end
        end

        event
        def update(id, attributes, scope: scoped(:updated))
          attributes = encode(attributes)
          update_impl(id, attributes, scope:)
        end

        protected def update_impl(id, attributes, scope:)
          # :nocov:
          raise NotImplementedError, "please implement update"
          # :nocov:
        end

        event(creation: true)
        def create(attributes)
          scoped(:create)
          attributes = encode(attributes)
          create_impl(attributes)
        end

        protected def create_impl(attributes)
          # :nocov:
          raise NotImplementedError, "please implement create"
          # :nocov:
        end

        event
        def delete(id, scope: scoped(:delete))
          id = find_by({ id: }, scope:)&.id

          return false unless id

          delete_impl(id)
        end

        protected def delete_impl(id)
          # :nocov:
          raise NotImplementedError, "please implement delete"
          # :nocov:
        end

        def find(id, scope: scoped(:read), included: [], record: self.class.model_class)
          find_by({ self.class.primary_key => id }, scope:, included:, record:)
        end

        def find!(id, scope: scoped(:read), included: [], record: self.class.model_class)
          find_by!({ self.class.primary_key => id }, scope:, included:, record:)
        end

        def find_by(
          filter,
          scope: scoped(:read),
          included: [],
          record: self.class.model_class
        )
          filter = encode_filters(filter)

          result = find_by_impl(
            filter,
            scope:,
          )

          return if result.nil?

          result = decode(result)

          set = prepare_included(included, [result], record:)

          record.new(result, include_set: set)
        end

        def find_by_impl(
          filter,
          scope:,
          included: []
        )
          # :nocov:
          raise NotImplementedError, "please implement find_by"
          # :nocov:
        end

        query
        def index(
          filters,
          scope: scoped(:read),
          included: [],
          page: 1,
          items_per_page: 1_000,
          sort: nil,
          record: self.class.model_class,
          query_count: true
        )
          filters = encode_filters(filters)

          collection, metadata = index_impl(
            filters,
            scope:,
            page:,
            items_per_page:,
            sort:,
            query_count:
          )

          set = prepare_included(included, collection, record:)

          Verse::Util::ArrayWithMetadata.new(
            collection.map{ |elm|
              record.new(
                decode(elm), include_set: set
              )
            },
            metadata:
          )
        end

        protected def index_impl(
          filters,
          scope:,
          page:,
          items_per_page:,
          sort:,
          query_count:
        )
          # :nocov:
          raise NotImplementedError, "please implement index"
          # :nocov:
        end

        ## === Selectors throwing exceptions ===
        def find_by!(filters = {}, **opts)
          record = find_by(filters, **opts)

          raise Verse::Error::RecordNotFound, filters.inspect unless record

          record
        end

        def update!(id, attributes, scope: scoped(:update))
          output = update(id, attributes, scope:)
          raise Verse::Error::RecordNotFound, id unless output
        end

        def delete!(id, scope: scoped(:delete))
          output = delete(id, scope:)
          raise Verse::Error::RecordNotFound, id unless output
        end
        ## === ===

        def with_metadata(metadata)
          old_metadata = @metadata
          @metadata = @metadata.merge(metadata)
          yield
        ensure
          @metadata = old_metadata
        end

        # Redefine if the adapter allow multiple connection for read or write.
        def mode(_read_write, &_block)
          yield
        end

        def chunked_index(filters, scope: scoped(:read), included: [], page: 1, items_per_page: 50, sort: nil)
          Verse::Util::Iterator.chunk_iterator page do |current_page|
            result = index(
              filters,
              scope:,
              included:,
              page: current_page,
              items_per_page:,
              sort:,
              query_count: false
            )

            result.count == 0 ? nil : result
          end
        end

        # Disable automatic events on this specific call.
        # ```
        #  repo.no_event do
        #    repo.update(...) # Not event will be triggered to the event bus.
        #  end
        # ```
        #
        def no_event
          @disable_event = true
          yield(self)
        ensure
          @disable_event = false
        end

        protected

        def decode(hash)
          return hash unless self.class.encoders

          dup = hash.dup

          dup.each do |key, value|
            encoder = self.class.encoders[key.to_s]

            next unless encoder

            dup[key] = encoder.decode(value)
          end

          dup
        end

        def encode(hash)
          return hash unless self.class.encoders

          dup = hash.dup

          dup.each do |key, value|
            encoder = self.class.encoders[key.to_s]

            next unless encoder

            dup[key] = encoder.encode(value)
          end

          dup
        end

        def encode_filters(hash)
          return hash unless self.class.encoders

          dup = hash.dup

          dup.each do |key, value|
            field, operator = key.to_s.split("__")

            encoder = self.class.encoders[field]

            next unless encoder

            dup[key] = if value.is_a?(Array) && filtering.expect_array?(operator)
                         value.map{ |x| encoder.encode(x) }
                       else
                         encoder.encode(value)
                       end
          end

          dup
        end

        def encode_array(array)
          return array unless self.class.encoders

          array.map{ |h| encode(h) }
        end

        def decode_array(array)
          return array unless self.class.encoders

          array.map{ |h| decode(h) }
        end

        def scoped(action)
          # :nocov:
          raise NotImplementedError, "please redefine scoped on child repositories and use @auth_context to filter."
          # :nocov:
        end

        # return a hash tree from the include list:
        # ["a.b.c", "c.d"] => { a: {b: {c: {}}}, c: {d: {}} }
        def tree_from_include_list(include, root = {})
          include.filter{ |x| x.is_a?(String) }.each_with_object(root) do |inc, root| # rubocop:disable Lint/ShadowingOuterLocalVariable
            first_part, remainer = inc.split "."
            root[first_part] = tree_from_include_list(
              [remainer].compact,
              root.fetch(first_part, {})
            )
          end
        end

        def prepare_included(included_list, collection, record: self.class.model_class)
          included_list = included_list.map(&:to_s)
          set = IncludeSet.new(included_list)
          tree = tree_from_include_list included_list

          tree.each_key do |key|
            regexp = /^#{key}($|\.)/

            sub_included = \
              included_list \
              .filter{ |x| x =~ regexp } \
              .map{ |x| x.gsub(regexp, "") }
              .reject(&:empty?)

            relation = record.relations.fetch(key.to_sym){ raise "Relation not found: #{key}" }

            # include_list,                                     # the list we store
            # ->(included) { included[primary_key.to_s] },      # The index where to store in the set
            # ->(record, set) { set[record[foreign_key.to_s]] } # the method to reconnect the set
            list, index_callback, record_callback = relation.call(
              collection, Auth::Context[:system], sub_included
            )

            set.set_lookup_method([record, key], &record_callback)

            list.each do |element|
              set.add([record, key], index_callback.call(element), element)
            end
          end

          set
        end
      end
    end
  end
end
