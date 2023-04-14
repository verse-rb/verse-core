# frozen_string_literal: true

RSpec.describe Verse::Util::Iterator do
  let(:subject){
    Verse::Util::Iterator
  }

  let(:data) { [1, 2, 3, 4, 5, 6, 7] }

  (1..2).each do |size|
    context "with chunk_size #{size}" do
      it "iterates over every item from the data array" do
        iterator = subject.chunk_iterator do |chunk|
          data.slice(chunk * size, size)
        end

        iterator.each_with_index do |value, i|
          expect(value).to eq data[i]
        end
      end

      it "calls block once previous block calls return has been fully enumerated (to allow streaming of big data)" do
        block_call_count = 0

        iterator = subject.chunk_iterator do |chunk|
          block_call_count += 1
          data.slice(chunk * size, size)
        end

        expectation = data.each_with_index.map do |_, n|
          n += 1
          expected_block_call_count = n / size + n % size
          { n_each_called: n, block_call_count: expected_block_call_count }
        end

        result = iterator.each_with_index.map do |_, n|
          { n_each_called: n + 1, block_call_count: block_call_count }
        end

        expect(result).to eq(expectation)
      end
    end
  end
end
