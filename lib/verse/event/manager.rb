# frozen_string_literal: true

module Verse
  module Event
    # main module for event manager related classes
    module Manager
      extend self

      # Broadcast mode describe a listener which is
      # interested in an event type but won't consume it.
      #
      # Use this mode if you want the event to be shared
      # across multiple instance of a same service.
      #
      # Broadcasted messages do not require acknowledgement, and
      # are not persisted nor guaranteed to be delivered.
      #
      # Example of broadcasted messages are cache invalidation,
      # multiple request command like instance telemetry etc.
      MODE_BROADCAST = :broadcast

      # Consumer mode describe a listener which is
      # interested in an event type and will consume it.
      # Use this mode if you want the event to be consumed
      # by only one instance of a same service.
      #
      # In this mode, events SHOULD BE persisted, repeateable,
      # and guaranteed to be delivered at most to one service.
      MODE_CONSUMER  = :consumer

      # Command mode describe a listener which is
      # interested in an event requiring a reply.
      #
      # Output of the method bounded to this mode will be
      # sent back to reply-to channel.
      #
      # Use this mode if you want the event to be consumed
      # by only one instance of a same service.
      MODE_COMMAND   = :command

      @em_types = {}

      def self.em_types
        @em_types
      end

      def [](name)
        @em_types.fetch(name.to_sym) do
          raise ArgumentError, "Unknown event manager type: #{name}"
        end
      end

      def add_event_manager_type(name, event_manager_class)
        @em_types[name.to_sym] = event_manager_class
      end
    end
  end
end
