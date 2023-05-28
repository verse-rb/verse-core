# frozen_string_literal: true

module Verse
  module Model
    # This class is used to store included data for a record.
    # Included data are records related to the current model via
    # belongs_to, has_one or has_many associations.
    class IncludeSet
      attr_reader :included

      def initialize(included)
        @included = included
        @object_table = {}
        @lookup_method_table = {}
      end

      # Add an object to the include set.
      # The object is stored in a hash table, using the namespace and id
      # as key.
      # @param namespace [String] the namespace of the object (e.g. table name/record type)
      # @param id [String] the id of the object
      # @param data [Object] the object to store
      def add(namespace, id, data)
        key = [namespace, id]

        @object_table[key] ||= []
        @object_table[key] << data

        self
      end

      # Get a record from the include set.
      # @param namespace [String] the namespace of the object (e.g. table name/record type)
      # @param id [String] the id of the object
      # @return [Object] the record
      def get(namespace, id)
        key = [namespace, id]
        @object_table[key]
      end

      # :nodoc:
      def set_lookup_method(namespace, &block)
        @lookup_method_table[namespace] = block
      end

      # :nodoc:
      def get_lookup_method(namespace)
        @lookup_method_table[namespace]
      end
    end
  end
end
