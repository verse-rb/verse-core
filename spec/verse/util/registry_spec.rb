# frozen_string_literal: true

require "spec_helper"
require "verse/util/registry"
require "verse/util/error"

# Dummy classes for testing
class TestAdapterOne
  attr_reader :config

  def initialize(config = {})
    @config = config
  end

  def identity = :one
end

class TestAdapterTwo
  attr_reader :config

  def initialize(config = {})
    @config = config
  end

  def identity = :two
end

RSpec.describe Verse::Util::Registry do
  subject(:registry) { Verse::Util::Registry }

  before(:each) do
    registry.reset!
  end

  describe ".register and .resolve" do
    it "registers and resolves a class adapter" do
      registry.register(:test_service, :one, TestAdapterOne)
      instance = registry.resolve(:test_service, :one)
      expect(instance).to be_a(TestAdapterOne)
    end

    it "returns the same instance when resolved multiple times (singleton behavior)" do
      registry.register(:test_service, :one, TestAdapterOne)
      instance1 = registry.resolve(:test_service, :one)
      instance2 = registry.resolve(:test_service, :one)
      expect(instance1).to be_a(TestAdapterOne)
      expect(instance2).to be_a(TestAdapterOne)
      expect(instance1.object_id).to eq(instance2.object_id)
    end

    it "registers and resolves a proc adapter" do
      registry.register(:test_service, :proc_adapter, ->(config) { TestAdapterTwo.new(config) })
      instance = registry.resolve(:test_service, :proc_adapter)
      expect(instance).to be_a(TestAdapterTwo)
    end

    it "returns the same instance for proc adapter when resolved multiple times" do
      registry.register(:test_service, :proc_adapter, ->(config) { TestAdapterTwo.new(config) })
      instance1 = registry.resolve(:test_service, :proc_adapter)
      instance2 = registry.resolve(:test_service, :proc_adapter)
      expect(instance1.object_id).to eq(instance2.object_id)
    end

    it "raises ConfigurationError if adapter name is not registered for the type" do
      registry.register(:test_service, :one, TestAdapterOne)
      expect {
        registry.resolve(:test_service, :non_existent)
      }.to raise_error(Verse::Util::Error::ConfigurationError, "Adapter ':non_existent' not registered for utility type ':test_service'.")
    end

    it "raises ConfigurationError if utility type is not registered at all" do
      expect {
        registry.resolve(:unknown_service, :one)
      }.to raise_error(Verse::Util::Error::ConfigurationError, "Adapter ':one' not registered for utility type ':unknown_service'.")
    end
  end

  describe ".set_default_adapter and .resolve (default)" do
    before do
      registry.register(:test_service, :default_one, TestAdapterOne)
      registry.register(:test_service, :another_two, TestAdapterTwo)
    end

    it "resolves the default adapter when no name is given" do
      registry.set_default_adapter(:test_service, :default_one)
      instance = registry.resolve(:test_service)
      expect(instance).to be_a(TestAdapterOne)
    end

    it "allows overriding the default by specifying a name" do
      registry.set_default_adapter(:test_service, :default_one)
      instance = registry.resolve(:test_service, :another_two)
      expect(instance).to be_a(TestAdapterTwo)
    end

    it "raises ConfigurationError if no default is set and no name is given" do
      # No default set for :test_service here
      expect {
        registry.resolve(:test_service)
      }.to raise_error(Verse::Util::Error::ConfigurationError, "No default adapter configured for utility type ':test_service'.")
    end

    it "returns the same instance for default adapter when resolved multiple times" do
      registry.set_default_adapter(:test_service, :default_one)
      instance1 = registry.resolve(:test_service)
      instance2 = registry.resolve(:test_service)
      expect(instance1.object_id).to eq(instance2.object_id)
    end
  end

  describe ".adapter_config" do
    it "passes config to a class adapter instance" do
      registry.register(:test_service, :one, TestAdapterOne)
      registry.adapter_config(:test_service, :one, { setting: "value1" })
      instance = registry.resolve(:test_service, :one)
      expect(instance.config).to eq({ setting: "value1" })
    end

    it "passes config to a proc adapter instance" do
      registry.register(:test_service, :proc_adapter, ->(config) { TestAdapterTwo.new(config) })
      registry.adapter_config(:test_service, :proc_adapter, { setting: "value2" })
      instance = registry.resolve(:test_service, :proc_adapter)
      expect(instance.config).to eq({ setting: "value2" })
    end

    it "passes empty hash if no config is set" do
      registry.register(:test_service, :one, TestAdapterOne)
      instance = registry.resolve(:test_service, :one)
      expect(instance.config).to eq({})
    end

    it "uses specific config for a named adapter even if default has different config" do
      registry.register(:test_service, :one, TestAdapterOne)
      registry.register(:test_service, :two, TestAdapterOne) # Same class, different adapter name

      registry.set_default_adapter(:test_service, :one)
      registry.adapter_config(:test_service, :one, { setting: "default_val" })
      registry.adapter_config(:test_service, :two, { setting: "specific_val" })

      instance_default = registry.resolve(:test_service)
      instance_specific = registry.resolve(:test_service, :two)

      expect(instance_default.config).to eq({ setting: "default_val" })
      expect(instance_specific.config).to eq({ setting: "specific_val" })
    end
  end

  describe "isolation between types" do
    it "keeps configurations for different types separate" do
      registry.register(:type_a, :adapter_x, TestAdapterOne)
      registry.adapter_config(:type_a, :adapter_x, { config_a: true })
      registry.set_default_adapter(:type_a, :adapter_x)

      registry.register(:type_b, :adapter_y, TestAdapterTwo)
      registry.adapter_config(:type_b, :adapter_y, { config_b: true })
      registry.set_default_adapter(:type_b, :adapter_y)

      instance_a = registry.resolve(:type_a)
      instance_b = registry.resolve(:type_b)

      expect(instance_a).to be_a(TestAdapterOne)
      expect(instance_a.config).to eq({ config_a: true })

      expect(instance_b).to be_a(TestAdapterTwo)
      expect(instance_b.config).to eq({ config_b: true })
    end
  end

  describe ".reset!" do
    it "clears all registrations, configs, and defaults" do
      registry.register(:test_service, :one, TestAdapterOne)
      registry.adapter_config(:test_service, :one, { setting: "value" })
      registry.set_default_adapter(:test_service, :one)

      registry.reset!

      expect {
        registry.resolve(:test_service, :one)
      }.to raise_error(Verse::Util::Error::ConfigurationError)

      expect {
        registry.resolve(:test_service)
      }.to raise_error(Verse::Util::Error::ConfigurationError, "No default adapter configured for utility type ':test_service'.")
    end
  end
end
