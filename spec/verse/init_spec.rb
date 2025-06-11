# frozen_string_literal: true

require "spec_helper"
require "verse/util/inflector"
require "verse/distributed/impl/memory_kv_store"
require "verse/distributed/impl/local_lock"
require "verse/distributed/impl/memory_counter"

RSpec.describe Verse do
  before do
    Verse.start(
      :server, config_path: "./spec/verse/spec_data/config.yml"
    )
  end

  after do
    Verse.stop
  end

  describe ".kvstore" do
    it "returns an instance of MemoryKVStore" do
      expect(Verse.kvstore).to be_a(Verse::Distributed::Impl::MemoryKVStore)
    end
  end

  describe ".lock" do
    it "returns an instance of LocalLock" do
      expect(Verse.lock).to be_a(Verse::Distributed::Impl::LocalLock)
    end
  end

  describe ".counter" do
    it "returns an instance of MemoryCounter" do
      expect(Verse.counter).to be_a(Verse::Distributed::Impl::MemoryCounter)
    end
  end
end
