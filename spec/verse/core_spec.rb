# frozen_string_literal: true

RSpec.describe Verse do
  it "has a version number" do
    expect(Verse::VERSION).not_to be nil
  end
end
