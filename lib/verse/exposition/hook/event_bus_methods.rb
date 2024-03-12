# frozen_string_literal: true

module Verse
  module Exposition
    module Hook
      module EventBusMethods
        # Subscribe to the event bus as a consumer.
        # As consumer, only one instance of the current service is going
        # to be triggered by an event.
        # @param channel [String|Array<String>] The channels to subscribe to.
        #  If an array is given, the service will be subscribed to all of them.
        # @param ack_type [Symbol] The type of acknowledgement to use.
        #                          By default, will acknowledge the message
        #                          automatically on reception.
        def on_event(channel, ack_type: :auto, **opts)
          EventBus.new(self, channels: channel, type: Verse::Event::Manager::MODE_CONSUMER, ack_type: ack_type, **opts)
        end

        def on_resource_event(resource, event, ack_type: :auto, **opts)
          EventBus.new(self, resource_channels: [resource, event], type: Verse::Event::Manager::MODE_CONSUMER, ack_type: ack_type, **opts)
        end

        # Subscribe to the event bus as a command.
        # As command, the service will be triggered by an event
        # and will be able to reply to the event.
        def on_command(command_name, absolute: false, auth: :header, no_reply: false, **opts)
          EventBus.new(
            self,
            channels: command_name,
            type: Verse::Event::Manager::MODE_COMMAND,
            **opts.merge(
              no_reply: no_reply,
              auth: auth,
              absolute: absolute
            )
          )
        end

        # Subscribe to the event bus to broadcasted messages.
        # Broadcasted message are sent to all instances at once.
        # Broadcasted messages do not require acknowledgement.
        #
        # This is useful for catching notification type messages sent to all
        # services, for example for cache invalidation.
        def on_broadcast(channel, **opts)
          EventBus.new(
            self,
            channels: channel,
            type: Verse::Event::Manager::MODE_BROADCAST,
            **opts
          )
        end
      end

      Verse::Exposition::Base.extend(EventBusMethods)
    end
  end
end
