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

      field?(:cache, Hash) do
        field(:adapter, String).filled.default("Verse::Cache::Impl::MemoryCacheAdapter")
        field?(:config, Hash).default({})
      end.default({
        adapter: "Verse::Cache::Impl::MemoryCacheAdapter",
        config: {}
      })

      field?(:kv_store, Hash) do
        field(:adapter, String).filled.default("Verse::Distributed::Impl::MemoryKVStore")
        field?(:config, Hash).default({})
      end.default({
        adapter: "Verse::Distributed::Impl::MemoryKVStore",
        config: {}
      })

      field?(:lock, Hash) do
        field(:adapter, String).filled.default("Verse::Distributed::Impl::LocalLock")
        field?(:config, Hash).default({})
      end.default({
        adapter: "Verse::Distributed::Impl::LocalLock",
        config: {}
      })

      field?(:counter, Hash) do
        field(:adapter, String).filled.default("Verse::Distributed::Impl::MemoryCounter")
        field?(:config, Hash).default({})
      end.default({
        adapter: "Verse::Distributed::Impl::MemoryCounter",
        config: {}
      })

      extra_fields
    end
  end
end
