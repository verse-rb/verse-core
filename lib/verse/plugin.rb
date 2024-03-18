# frozen_string_literal: true

require_relative "util/assertion"

module Verse
  module Plugin
    extend self

    include Verse::Util

    Error = Class.new(StandardError)
    NotFoundError = Class.new(Error)

    class DependencyError < Error
      ERROR_MSG_DEPENDS_MAP = "Plugin `%s` depends on `%s` (as `%s`) but it is not found."
      ERROR_MSG_DEPENDS = "Plugin `%s` depends on `%s` but it is not found."
    end

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

    # Return the plugin with the given name.
    # @param name [String] the name of the plugin
    # @return [Verse::Plugin::Base+] the plugin
    def [](name)
      @plugins.fetch(name.to_sym) do
        raise NotFoundError, "Plugin not found: `#{name}`"
      end
    end

    def exists?(name)
      @plugins.key?(name.to_sym)
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
      @plugins.each_value do |x|
        x.on_start(mode)
      end
    rescue StandardError => e
      Verse.logger.fatal(e)
      exit(-1)
    end

    def stop
      @plugins.each_value do |p|
        p.on_stop
      rescue StandardError => e
        Verse.logger.error(e)
      end
    end

    def finalize
      @plugins.each_value do |p|
        p.on_finalize
      rescue StandardError => e
        Verse.logger.error(e)
      end

      @plugins.clear
    end

    # Load a specific plugin
    # @param plugin [Hash] the plugin configuration
    # @param logger [Logger] the logger to use when initializing the plugin
    def load_plugin(plugin, logger = Verse.logger)
      type = plugin.fetch(:class)
      name = plugin.fetch(:name, type)
      config = plugin.fetch(:config, {})

      dependencies = plugin.fetch(:dep, {})

      logger.debug{ "Plugin `#{name}`: init plugin" }

      plugin_class = Reflection.constantize(type)
      plugin = plugin_class.new(name.to_s, config, dependencies, logger)

      register_plugin(plugin)

      logger.debug{ "Plugin `#{name}`: init sequence completed" }
    rescue StandardError => e
      logger.fatal(e)
      exit(-1)
    end

    # Add plugin to the list of loaded plugins
    # @param plugin [Verse::Plugin::Base+] the plugin to register
    def register_plugin(plugin)
      name = plugin.name.to_sym

      @plugins.key?(name) and raise "Plugin already registered: `#{name}`"

      @plugins[name] = plugin
    end

    private

    def infer_name_and_class(str)
      name = str.scan(/([^<][\w:]+)/).first&.first
      klass_name   = str.scan(/<([\w:]+)>/).first&.first
      klass_name ||= name

      if klass_name !~ /[A-Z]/
        klass_name = "Verse::#{StringUtil.camelize(klass_name)}::Plugin"
      end

      [name, klass_name]
    end
  end
end
