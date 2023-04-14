# frozen_string_literal: true

RSpec.describe Verse::Util::Assertion do
  it "assert correctly" do
    Verse::Util::Assertion.assert(true, "This should not raise")

    expect do
      Verse::Util::Assertion.assert(false, "This should raise")
    end.to raise_error(/This should raise/)
  end

  it "assert correctly with block" do
    Verse::Util::Assertion.assert(true) { "This should not raise" }

    expect do
      Verse::Util::Assertion.assert(false) { "This should raise" }
    end.to raise_error(/This should raise/)
  end

  it "assert correctly with custom error class" do
    Verse::Util::Assertion.assert(true, "This should not raise", StandardError)

    expect do
      Verse::Util::Assertion.assert(false, "This should raise", StandardError)
    end.to raise_error(StandardError, /This should raise/)
  end
end
