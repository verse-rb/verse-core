require_relative "../spec_data/exposition/sample_exposition_eb"

RSpec.describe Verse::Exposition do
  before :suite do
    Verse.start(:server, config_path: File.join(__dir__, "../spec_data/config.yml"))
    SampleExpositionEb.register
  end

  before :each do
    SampleExpositionEb.something_happened = nil
  end

  it "exposes on event" do
    Verse.publish("CHANNEL.spec.test", { content: "John" })

    expect(SampleExpositionEb.something_happened).to eq(
      "on_test"
    )
  end

  it "exposes on command" do
    expect(Verse.request("sum", { numbers: [1, 2, 3] })).to eq(6)
  end

  it "exposes on broadcast" do
    Verse.publish("CHANNEL.spec.broadcast", {})
    expect(SampleExpositionEb.something_happened).to eq(true)
  end

end