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
    end
  end
end
