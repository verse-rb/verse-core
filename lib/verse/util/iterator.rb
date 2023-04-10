# frozen_string_literal: true

module Verse
  module Util
    module Iterator
      module_function

      # This method returns an Enumerator that iterates over chunks of data retrieved on each call.
      # It takes an optional parameter, chunk, and a block.
      # The Enumerator yields values from the block while the loop continues,
      # passing each value through the each method and adding it to the yielder.
      #
      # This function is a sleek and efficient way to break down large chunks of data,
      # making it easy to work with and iterate through.
      #
      # @param chunk [Integer] an optional parameter, the starting value for the the chunk iterator (default 0)
      # @yield [block] the block of code to be executed for each chunk
      # @return [Enumerator] an enumerator that iterates over chunks of data
      def self.chunk_iterator(chunk = 0, &_block)
        Enumerator.new do |yielder|
          while data = yield(chunk)
            data = [data] unless data.respond_to?(:each)

            data.each { |v| yielder << v }

            chunk += 1
          end
        end
      end
    end
  end
end
