# frozen_string_literal: true

require_relative "util/assertion"

module Verse
  module Plugin
    module_function

    include Verse::Util

    PluginNotFoundError = Class.new(RuntimeError)

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

          name, klass = infer_name_and_class(plugin.fetch(:name))

          plugin[:name]    ||= name
          plugin[:class]     = klass
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

    private def infer_name_and_class(str)
      name         = str.scan(/([^<][\w:]+)/).first&.first
      klass_name   = str.scan(/<([\w\:]+)>/).first&.first
      klass_name ||= name

      if klass_name !~ /[A-Z]/
        klass_name = "Verse::Plugin::#{StringUtil.camelize(klass_name)}::Plugin"
      end

      [name, klass_name]
    end

    # Return the plugin with the given name.
    # @param name [String] the name of the plugin
    # @return [Verse::Plugin::Base+] the plugin
    def [](name)
      @plugins.fetch(name.to_sym) do
        raise PluginNotFoundError, "Plugin not found: `#{name}`"
      end
    end

    def all
      @plugins
    end

    def init
      plugins = @plugins.values
      plugins.each(&:on_init)
      plugins.each(&:check_dependencies!)
    end

    def start(mode)
      case mode
      when :server
        @plugins.values.each(&:on_start)
      when :spec
        @plugins.values.each(&:on_spec_helper_load)
      when :rake
        @plugins.values.each(&:on_rake)
      end
    rescue => e
      Verse.logger.fatal(e)
      exit(-1)
    end

    def stop
      @plugins.values.each do |p|
        p.on_stop
      rescue => e
        Verse.logger.error(e)
      end
    end

    def finalize
      @plugins.values.each do |p|
        p.on_finalize
      rescue => e
        Verse.logger.error(e)
      end

      @plugins.clear
    end

    # Load a specific plugin
    # @param plugin [Hash] the plugin configuration
    # @param logger [Logger] the logger to use when initializing the plugin
    protected def load_plugin(plugin, logger = Verse.logger)
      type = plugin.fetch(:class)
      name = plugin.fetch(:name, type)
      config = plugin.fetch(:config, {})

      dependencies = plugin.fetch(:map, {})

      logger.debug{ "Plugin `#{name}`: Initializing plugin" }

      if type =~ /[A-Z]/
        plugin_class_str = type
      else
        plugin_class_str = "Verse::Plugin::#{StringUtil.camelize(type)}::Plugin"
      end

      plugin_class = Reflection.get(plugin_class_str)
      plugin = plugin_class.new(name.to_s, config, dependencies, logger)

      register_plugin(plugin)

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