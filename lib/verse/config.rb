# frozen_string_literal: true

require "yaml"

require_relative "util/hash_util"
require_relative "error/base"

module Verse
  module Config
    extend self

    include Verse::Util

    SchemaError = Class.new(Verse::Error::Base)

    # @return [Hash] The current configuration hash.
    def config
      @config
    end

    # Initialize the microservice within the current path.
    #
    # The config.yml file is the default config file, and will be loaded first.
    # The config.[environment].yml file is the environment specific config file,
    # and will be loaded second.
    #
    # Configuration hash will be merged in the order of the files.
    #
    # @param config_path [String] Path to the config file. Can be a directory
    #        or a simple file.
    def init(config_path = "./config")
      @config = {}

      lookup = [
        File.join(config_path, "config.yml"),
        File.join(config_path, "config.#{Verse.environment}.yml"),
        File.join(config_path),
      ].select do |file|
        File.exist?(file) && !File.directory?(file)
      end

      if lookup.empty?
        raise "No config file found (looked at #{config_path})"
      end

      lookup.each(&method(:inject_to_config))

      validate_config_schema!
    end

    protected def validate_config_schema!
      result = Verse::Config::Schema.validate(
        @config
      )

      @config = result.value

      return unless result.errors.any?

      raise Verse::Config::SchemaError, "Config errors: #{result.errors.to_h}"
    end

    # :nodoc:
    def inject_to_config(file)
      yaml_content = ERB.new(File.read(file)).result

      @config.merge!(
        HashUtil.deep_symbolize_keys(
          YAML.safe_load(yaml_content)
        )
      )
    end
  end
end
