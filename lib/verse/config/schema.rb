# frozen_string_literal: true

module Verse
  module Config
    SERVICE_NAME = /[a-z0-9_-]+/
    PLUGIN_NAME = /[a-z0-9_]+( <[a-zA-Z0-9:]+>)?/

    Schema = Verse::Schema.define do
      field(:service_name, String).filled.rule("bad_format"){ |value| value =~ SERVICE_NAME }
      field(:description, String).optional

      field(:version, String).optional

      field?(:plugins, Array) do
        field(:name, String).filled.rule("bad_format") { |value| value =~ PLUGIN_NAME }
        field(:config, Hash).optional
        field(:dep, Hash).optional
      end

      field?(:logging, Hash) do
        field(:level, String).filled
        field(:file, String).optional.filled
        field(:show_full_error, TrueClass).optional.filled
      end

      field?(:event_bus, Hash) do
        field(:adapter, String).filled
        field(:config, Hash).optional
      end

      field?(:utilities, Hash) do
        field?(:distributed_hash, Hash) do # Renamed from distributed_set
          field(:adapter, Symbol).filled.default(:memory)
          field(:config, Hash).optional.default({})
        end
        field?(:distributed_lock, Hash) do
          field(:adapter, Symbol).filled.default(:memory)
          field(:config, Hash).optional.default({})
        end
        field?(:distributed_counter, Hash) do
          field(:adapter, Symbol).filled.default(:memory)
          field(:config, Hash).optional.default({})
        end

        field?(:inflector, Hash) do
          field(:adapter, Symbol).filled.default(:default) # :default will map to Verse::Util::Inflector
          field(:config, Hash).optional.default({}) # For custom exceptions, e.g., { verb_exceptions: {...} }
        end
      end
    end
  end
end
