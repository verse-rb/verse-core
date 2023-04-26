module Verse
  module Spec
    module Helpers

      def trigger_event(channel, data = nil)
        Verse.event_manager.publish(channel, data)
      end

      def self.included
      end


    end
  end
end
