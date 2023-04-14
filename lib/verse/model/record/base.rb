# frozen_string_literal: true

module Verse
  module Model
    module Record
      # Record acts as a model mapper (read-only) object.
      # @abstract
      class Base
        @record_root_path       = "App::Model"
        @repositories_root_path = "App::Model"
        @primary_key            = :id

        attr_reader :relations, :fields, :included

        # Initialize a new record. Include set is used to append the relations to
        # the record.
        #
        # @param fields [Hash] The fields of the record.
        # @param include_set [Verse::Model::Record::IncludeSet] The include set.
        def initialize(fields, include_set: nil)
          @fields     = {}
          @relations  = {}
          @included   = include_set&.included || []

          @fields = fields.slice(*self.class.fields.map(&:to_sym)).freeze

          return unless include_set

          self.class.relations.each do |name, _relation|
            lookup_method = include_set.get_lookup_method([self.class, name.to_s])

            next unless lookup_method

            idx = lookup_method.call(self)

            @relations[name] = include_set.get(
              [self.class, name.to_s], idx
            )
          end

          @relations.freeze
        end

        # Get the (raw) field value by key.
        # @param key [Symbol] The key of the field.
        # @return [Object] The value of the field.
        def [](key)
          @fields[key.to_sym]
        end

        # Fetch the (raw) field value by key. If the field is not found,
        # the block will be called.
        def fetch(key, &block)
          @fields.fetch(key.to_sym, &block)
        end

        # Get the raw fields of the record.
        def to_h
          @fields.dup
        end

        # Get the id of the record. `id` of the record is the primary key.
        def id
          @fields[self.class.primary_key.to_sym]
        end

        def type
          self.class.type
        end

        # :nodoc:
        def self.inherited(subklass)
          super

          subklass.instance_eval do
            @fields    = {}
            @relations = {}
            extend ClassMethods
          end
        end
      end
    end
  end
end
