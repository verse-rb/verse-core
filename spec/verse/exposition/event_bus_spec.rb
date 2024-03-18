# frozen_string_literal: true

require_relative "../spec_data/exposition/sample_exposition_eb"

RSpec.describe Verse::Exposition do
  before :each do
    Verse.start(:server,
                config_path: File.join(__dir__, "../spec_data/config.yml"))
    SampleExpositionEb.register

    SampleExpositionEb.something_happened = nil
  end

  after :each do
    Verse.stop
  end

  it "exposes on event" do
    Verse.publish("CHANNEL.spec.test", { content: "John" })

    expect(SampleExpositionEb.something_happened).to eq(
      "on_test"
    )
  end

  it "exposes on command" do
    expect(
      Verse.request(
        "verse_spec.sum", { numbers: [1, 2, 3] }
      ).content[:output]
    ).to eq(6)
  end

  it "exposes on command using request_all" do
    expect(
      Verse.request_all(
        "verse_spec.sum", { numbers: [1, 2, 3] }, timeout: 0.01
      ).first.content[:output]
    ).to eq(6)
  end

  it "exposes on broadcast" do
    Verse.publish("CHANNEL.spec.broadcast", {})
    expect(SampleExpositionEb.something_happened).to eq(true)
  end
end
