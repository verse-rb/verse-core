# frozen_string_literal: true

require_relative "util/assertion"

module Verse
  module Plugin
    module_function

    include Verse::Util

    @plugins = {}

    #
    # ```
    # plugins:
    #  - name: redis # Optional, will use plugin as name
    #    plugin: redis # Can be a lower case string or a Ruby class
    #    config:
    #      url: redis://localhost:6379/0
    #      max_connections: 10
    #     mapping:
    #       db: sequel # Map `db` dependency to sequel plugin
    # ```
    def load_configuration(config)
      plugins = config.fetch(:plugins, [])

      case plugins
      when Array
        plugins = plugins.map do |plugin|
          plugin = plugin.dup

          plugin[:name]    ||= plugin.fetch(:plugin)
          plugin[:config]  ||= {}
          plugin[:mapping] ||= {}

          plugin
        end
      else
        raise "Invalid plugin configuration"
      end

      plugins.each do |plugin|
        load_plugin(plugin)
      end
    end

    # Return the plugin with the given name.
    # @param name [String] the name of the plugin
    # @return [Verse::Plugin::Base+] the plugin
    def [](name)
      @plugins.fetch(name.to_sym) do
        raise "Plugin not found: `#{name}`"
      end
    end

    # Load a specific plugin
    # @param plugin [Hash] the plugin configuration
    # @param logger [Logger] the logger to use when initializing the plugin
    protected def load_plugin(plugin, logger = Verse.logger)
      type = plugin.fetch(:plugin)
      name = plugin.fetch(:name, type)
      config = plugin.fetch(:config, {})

      dependencies = plugin.fetch(:map)

      logger.debug{ "Plugin `#{name}`: Initializing plugin" }

      if type =~ /[A-Z]/
        plugin_class_str = type
      else
        plugin_class_str = "Verse::Plugin::#{StringUtil.camelize(type)}::Plugin"
      end

      plugin_class = Reflection.get(plugin_class_str)
      plugin = plugin_class.new(name.to_s, config, dependencies, logger)

      register_plugin(plugin, type)

      logger.debug{ "Plugin `#{name}`: Initializing done" }
    rescue => e
      logger.fatal(e)
      exit(-1)
    end

    # Add plugin to the list of loaded plugins
    # @param plugin [Verse::Plugin::Base+] the plugin to register
    protected def register_plugin(plugin)
      name = plugin.name.to_sym

      @plugins.key?(name) and raise "Plugin already registered: `#{name}`"

      @plugins[name] = plugin
    end

  end
end