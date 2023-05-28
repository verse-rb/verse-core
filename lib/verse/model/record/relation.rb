# frozen_string_literal: true

module Verse
  module Model
    module Record
      class Relation
        attr_reader :name, :callback, :opts

        def initialize(name, opts, &callback)
          @name = name
          @callback = callback
          @opts = opts
        end

        def call(collection, auth_context, include_set)
          @callback.call(collection, auth_context, include_set)
        end
      end
    end
  end
end
