# frozen_string_literal: true

module Verse
  module Plugin
    class Base
      NO_DEPS = [].freeze

      attr_reader :name, :config, :dep_config, :logger

      def initialize(name, config, dep_config, logger)
        @name       = name
        @config     = config
        @dep_config = dep_config
        @logger     = logger

        init_dependencies
      end

      def check_dependencies!
        dependencies.each do |dep|
          send(dep)
        rescue NotFoundError => e
          dep_map = dep_config[dep]

          if dep_map
            raise DependencyError, DependencyError::ERROR_MSG_DEPENDS_MAP % [name, dep, dep_map]
          end

          raise DependencyError, DependencyError::ERROR_MSG_DEPENDS % [name, dep]
        end
      end

      # list of dependencies used by the plugin
      def dependencies
        NO_DEPS
      end

      # This is called after all plugins has been initialized
      # but the server is still not started.
      def on_init; end

      # This is called once all `on_init` of each plugins has been called.
      # This is where you should hook a server or any other long-lived object.
      # @param mode [Symbol] the mode of the server (:server, :spec, :rake, :console)
      def on_start(mode); end

      # This is called when the server is shutting down.
      def on_stop; end

      # This is the last step of the shutdown process.
      def on_finalize; end

      protected

      def init_dependencies
        dependencies.each do |dep|
          define_singleton_method(dep) do
            Verse::Plugin[@dep_config.fetch(dep, dep)]
          end
        end
      end
    end
  end
end
