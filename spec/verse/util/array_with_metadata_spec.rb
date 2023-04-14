# frozen_string_literal: true

RSpec.describe Verse::Util::ArrayWithMetadata do
  it "should be able to set metadata" do
    array = Verse::Util::ArrayWithMetadata.new([1, 2, 3], metadata: { foo: "bar" })
    expect(array.metadata).to eq(foo: "bar")
  end

  it "can delegate to array" do
    array = Verse::Util::ArrayWithMetadata.new([1, 2, 3], metadata: { foo: "bar" })
    expect(array.size).to eq(3)
  end
end
