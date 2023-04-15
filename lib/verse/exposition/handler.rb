# frozen_string_literal: true

module Verse
  module Exposition
    # Handler used to decorate the exposition methods.
    class Handler
      attr_reader :exposition, :handler, :opts

      def initialize(handler, exposition, **opts)
        @handler = handler
        @exposition = exposition
        @opts = opts

        @callback ||= -> {
          handler.call
        }
      end

      def call
        @callback.call
      end
    end
  end
end
