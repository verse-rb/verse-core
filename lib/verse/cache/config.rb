# frozen_string_literal: true

require "verse/schema"
require_relative "impl/memory_cache_adapter"
require_relative "impl/z_marshal_serializer"

module Verse
  module Cache
    ConfigSchema = Verse::Schema.define do
      field(:adapter, String).default("Verse::Cache::Impl::MemoryCacheAdapter")
      field(:serializer, String).default("Verse::Cache::Impl::ZMarshalSerializer")

      field(:config, Hash).default({})
    end

    Config = ConfigSchema.dataclass
  end
end
