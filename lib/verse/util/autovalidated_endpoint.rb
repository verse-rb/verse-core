# frozen_string_literal: true

module Verse
  module Util
    # Auto validated endpoint gives metadata for any endpoints,
    # and the possibility to validate any input/output schema.
    module AutovalidatedEndpoint
      attr_reader :input_schema, :output_schema

      # Describe the endpoint, for documentation purposes.
      # @param value [String] The description. If nil given, return the current
      #                       description value.
      # @return [String] The description value
      def desc(value = nil)
        if value
          @desc = value
        else
          @desc
        end
      end

      # Add metadata to the endpoint.
      # Metadata can be used to store any information about the endpoint.
      # It can be used for documentation and other purposes.
      #
      # @param value [Hash] The metadata to add. If nil given, return the current
      #                    metadata value.
      # @return [Hash] The metadata value
      # @example
      #  meta({ foo: "bar" })
      #  meta[:foo] # => "bar"
      #  meta[:foo] = "baz"
      def meta(value = nil)
        if value
          @meta = value
        else
          @meta
        end
      end

      # Process the input, clean and validate input.
      # @param input [Hash] The input to process
      # @return [Hash] The processed input, cleaned from unwanted keys and
      #                validated by verse-schema
      def process_input(input)
        return input if input_schema.nil?

        result = input_schema.validate(input)

        raise Verse::Error::ValidationFailed, result unless result.success?

        result.value
      end

      # Process the output, clean and validate output.
      # @param output [Hash] The output to process
      # @return [Hash] The processed output, cleaned from unwanted keys and
      #                validated by verse-schema
      def process_output(output)
        return output if output_schema.nil?

        result = output_schema.validate(output)

        raise Verse::Error::ValidationFailed, result unless result.success?

        result.value
      end

      # Define the input schema for this endpoint.
      # @param schema [Verse::Schema] The schema to use for validation
      # @param block [Proc] The block to use to build the schema
      # @raise [ArgumentError] If both schema and block are given
      def input(schema = nil, &block)
        if schema
          raise ArgumentError, "You can't use both schema and block" if block_given?

          @input_schema = schema
        else
          raise ArgumentError, "You must provide a block" unless block_given?

          @input_schema = Verse::Schema.define(&block)
        end
      end

      # Define the output schema for this endpoint.
      # @param schema [Verse::Schema] The schema to use for validation
      # @param block [Proc] The block to use to build the schema
      # @raise [ArgumentError] If both schema and block are given
      def output(schema = nil, &block)
        if schema
          raise ArgumentError, "You can't use both schema and block" if block_given?

          @output_schema = schema
        else
          raise ArgumentError, "You must provide a block" unless block_given?

          @output_schema = Verse::Schema.define(&block)
        end
      end
    end
  end
end
