# frozen_string_literal: true
module Verse
  module Plugin
    class Base
      NO_DEPS = [].freeze

      def initialize(name, config, dep_config, logger)
        @name       = name
        @config     = config
        @dep_config = dep_config
        @logger     = logger
      end

      def init_dependencies
        dependencies.each do |dep|
          define_singleton_method(dep) do
            Verse::Plugin[@dep_config.fetch(dep, dep)]
          end
        end
      end

      # list of dependencies used by the plugin
      def dependencies
        NO_DEPS
      end

      # This is called after all plugins has been initialized
      # but the server is still not started.
      def on_init
      end

      # This is called once all `on_init` of each plugins has been called.
      # This is where you should hook a server or any other long-lived object.
      def on_start
      end

      # This is called when the server is shutting down.
      def on_stop
      end

      # This is the last step of the shutdown process.
      def on_finalize
      end

      # This is called when the specs are run
      def on_spec_helper_load
      end

      # This is called to add external rake tasks.
      def on_rake
      end

    end
  end
end
