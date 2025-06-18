# frozen_string_literal: true

require "spec_helper"
require "verse/cache/cache"
require "verse/util/reflection"
require "tempfile"

class DummyCacheAdapter
  def initialize(**_opts); end

  def fetch(_key, _selector)
    "cached_value"
  end

  # rubocop:disable Naming/MethodParameterName
  def cache(_key, _selector, _value, ex:); end
  # rubocop:enable Naming/MethodParameterName

  def flush(_key, _selectors); end
end

class DummySerializer
  def serialize(payload)
    payload
  end

  def deserialize(payload)
    payload
  end
end

RSpec.describe Verse::Cache do
  let!(:config_file) do
    Tempfile.new("config.yml").tap do |f|
      f.write(
        {
          service_name: "test-service",
          cache: {
            adapter: "DummyCacheAdapter",
            serializer: "DummySerializer"
          }
        }.to_yaml
      )
      f.close
    end
  end

  before do
    Verse.start(
      "test",
      config_path: config_file.path
    )

    Verse::Cache.instance_variable_set(:@setup_done, false)
  end

  after do
    Verse.stop
    config_file.unlink
  end

  it "can be configured" do
    expect(
      Verse::Cache.with_cache("test") do
        "live_value"
      end
    ).to eq("cached_value")
  end
end
