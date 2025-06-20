# frozen_string_literal: true

RSpec.describe Verse::Config do
  it "uses configuration precedence rules" do
    path = File.expand_path("../..", __dir__)

    Verse.start(
      :server,
      root_path: path,
      config_path: "./spec/verse/spec_data/config_precedence"
    )

    expect(Verse::Config.config.extra_fields[:a_key_getting_overriden]).to eq("Overriden")
    expect(Verse::Config.config.extra_fields[:general_key]).to eq(1)
    expect(Verse::Config.config.extra_fields[:additional_stuff]).to be(true)
  ensure
    Verse.stop
  end
end
