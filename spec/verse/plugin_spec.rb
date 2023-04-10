require "spec_helper"

RSpec.describe Verse::Plugin do

  let(:config_hash) do
    {
      plugins: {
        redis: {
          plugin: "redis",
          config: {
            url: "redis://localhost:6379/0",
            max_connections: 10
          }
        }
      }
    }
  end

  context "with a configuration file with some plugins" do
    it "loads the plugins" do
      Verse.start(:server)
    end

    it "can retrieve a plugin" do
      pending
    end

    context "with a plugin that has a dependency" do
      it "fails to load the plugin if the dependency is not met" do
        pending
      end

      it "connects the proper dependency to the plugin" do
        pending
      end
    end

  end
end