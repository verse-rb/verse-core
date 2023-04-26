module Verse
  module Event
    module Manager
      extend self

      MODE_BROADCAST = :broadcast
      MODE_CONSUMER  = :consumer
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
