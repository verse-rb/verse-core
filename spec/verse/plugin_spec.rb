# frozen_string_literal: true

require "spec_helper"

require_relative "./spec_data/plugins_test"

RSpec.describe Verse::Plugin do
  context "with a configuration file with some plugins" do
    let :start do
      Verse.start(
        :server,
        config_path: File.join(
          __dir__, "spec_data", "plugin_config.yml"
        )
      )
    end

    after do
      Verse.stop
    end

    it "lists all plugins" do
      start

      expect(Verse::Plugin.all.size).to eq(5)
    end

    it "retrieves a plugin and config is loaded" do
      start

      plugin = Verse::Plugin[:test]
      expect(plugin).to be_a(Verse::Test::Plugin)
      expect(plugin.config).to eq({ a: true, foo: "bar" })
    end

    it "applies all the lifecycle of the plugin" do
      start

      plugin = Verse::Plugin[:test]
      expect(plugin.actions).to eq([:init, [:start, :server]])
    end

    context "with a plugin that has a dependency" do
      it "fails to load the plugin if the dependency is not met" do
        expect do
          Verse.start(:server,
                      config_path: File.join(
                        __dir__, "spec_data", "plugin_config_bad_1.yml"
                      ))
        end.to raise_error(
          Verse::Plugin::DependencyError,
          Verse::Plugin::DependencyError::ERROR_MSG_DEPENDS % [
            "plugin_with_dependencies", "dependent_plugin"
          ]
        )
      end

      it "fails to load the plugin if the dependency is not met (2)" do
        expect do
          Verse.start(:server,
                      config_path: File.join(__dir__, "spec_data", "plugin_config_bad_2.yml"))
        end.to raise_error(
          Verse::Plugin::DependencyError,
          Verse::Plugin::DependencyError::ERROR_MSG_DEPENDS_MAP % [
            "another_plugin_with_dependencies <plugin_with_dependencies>",
            "dependent_plugin",
            "dependent_plugin_2"
          ]
        )
      end
    end
  end
end
