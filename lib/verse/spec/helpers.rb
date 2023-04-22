module Verse
  module Spec
    module Helpers

      def trigger_event(channel, data = nil)
        Verse.event_manager.publish(channel, data)
      end

      def self.included
        RSpec::Matchers.define :receive_event do |channel|
          chain :with_content do |data|
            @content = data
          end

          match do |proc|
            sub = Verse.event_manager.subscribe(channel) do |message, _subject|
              @received = message
            end

            proc.call

            if @content
              @received&.content == @content
            else
              @received
            end
          ensure
            sub.unsubscribe
          end

          error_message do
            "expected block to receive event #{channel}"
          end

        end
      end


    end
  end
end
