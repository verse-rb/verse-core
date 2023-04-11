require "spec_helper"

require_relative "./data/plugins_test"

RSpec.describe Verse::Plugin do
  context "with a configuration file with some plugins" do
    let :start do
      Verse.start(:server,
        config_path: File.join(__dir__, "data", "plugin_config.yml")
      )
    end

    after do
      Verse.stop
    end

    it "can retrieve a plugin and config is loaded" do
      start

      plugin = Verse::Plugin[:test]
      expect(plugin).to be_a(Verse::Plugin::Test::Plugin)
      expect(plugin.config).to eq({ a: true, foo: "bar" })
    end

    it "will apply all the lifecycle of the plugin" do
      start

      plugin = Verse::Plugin[:test]
      expect(plugin.actions).to eq([:init, [:start, :server]])
    end

    context "with a plugin that has a dependency" do
      it "fails to load the plugin if the dependency is not met" do
        expect do
          Verse.start(:server,
            config_path: File.join(__dir__, "data", "plugin_config_bad_1.yml")
          )
        end.to raise_error(Verse::Plugin::DependencyError,
          "Plugin `plugin_with_dependencies` depends on " \
          "`dependent_plugin` but it is not found.")
      end

      it "fails to load the plugin if the dependency is not met (2)" do
        expect do
          Verse.start(:server,
            config_path: File.join(__dir__, "data", "plugin_config_bad_2.yml")
          )
        end.to raise_error(Verse::Plugin::DependencyError,
          "Plugin `another_plugin_with_dependencies <plugin_with_dependencies>` depends" \
          " on `dependent_plugin_2` (via dependent_plugin) but it is not found."
        )
      end
    end

  end
end