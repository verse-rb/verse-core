# frozen_string_literal: true

require_relative "./error"

module Verse
  module Util
    # Registry for utility adapters (e.g., distributed set, lock, counter, inflector).
    # Allows different implementations (memory, Redis, etc.) to be registered
    # and resolved based on configuration.
    module Registry
      @adapters = {} # Stores adapter classes or procs: { type => { name => class/proc } }
      @adapter_configs = {} # Stores specific configurations for adapters: { type => { name => config_hash } }
      @default_adapters = {} # Stores default adapter names for each type: { type => name }
      @resolved_instances = {} # Stores resolved singleton instances: { type => { name => instance } }

      class << self
        # Registers an adapter implementation for a given utility type and name.
        #
        # @param type [Symbol] The type of utility (e.g., :distributed_set, :distributed_lock).
        # @param name [Symbol] The name of the adapter (e.g., :memory, :redis).
        # @param adapter_class_or_proc [Class, Proc] The class of the adapter or a proc that returns an instance.
        #        If a proc is given, it will be called with the specific adapter configuration.
        def register(type, name, adapter_class_or_proc)
          @adapters[type] ||= {}
          @adapters[type][name] = adapter_class_or_proc
        end

        # Sets the configuration for a specific adapter.
        #
        # @param type [Symbol] The type of utility.
        # @param name [Symbol] The name of the adapter.
        # @param config [Hash] The configuration hash for this adapter instance.
        def adapter_config(type, name, config)
          @adapter_configs[type] ||= {}
          @adapter_configs[type][name] = config
        end

        # Sets the default adapter name for a utility type.
        #
        # @param type [Symbol] The type of utility.
        # @param name [Symbol] The name of the adapter to use as default.
        def set_default_adapter(type, name)
          @default_adapters[type] = name
        end

        # Resolves and returns an instance of the requested utility adapter.
        #
        # @param type [Symbol] The type of utility.
        # @param name [Symbol, nil] The specific adapter name. If nil, the configured default for the type is used.
        # @return [Object] An instance of the adapter.
        # @raise [Verse::Util::Error::ConfigurationError] if the adapter or default is not found/configured.
        def resolve(type, name = nil)
          adapter_name = name || @default_adapters[type]

          unless adapter_name
            raise Error::ConfigurationError, "No default adapter configured for utility type ':#{type}'."
          end

          # Check if instance already exists
          instance = @resolved_instances.dig(type, adapter_name)
          return instance if instance

          adapter_class_or_proc = @adapters.dig(type, adapter_name)
          unless adapter_class_or_proc
            raise Error::ConfigurationError, "Adapter ':#{adapter_name}' not registered for utility type ':#{type}'."
          end

          config = @adapter_configs.dig(type, adapter_name) || {}

          new_instance = \
            case adapter_class_or_proc
            when Class
              adapter_class_or_proc.new(config)
            when Proc
              adapter_class_or_proc.call(config)
            else
              raise Error::ConfigurationError, "Adapter ':#{adapter_name}' is not a valid class or proc."
            end

          # Store the new instance
          @resolved_instances[type] ||= {}
          @resolved_instances[type][adapter_name] = new_instance

          new_instance
        end

        # Clears all registrations, configurations, and resolved instances. Useful for testing.
        def reset!
          @adapters.clear
          @adapter_configs.clear
          @default_adapters.clear
          @resolved_instances.clear
        end
      end
    end
  end
end
