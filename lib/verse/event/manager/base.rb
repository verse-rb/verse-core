# frozen_string_literal: true

module Verse
  module Event
    module Manager
      class Base
        attr_reader :service_name, :config, :logger

        def initialize(service_name, config = nil, logger = Logger.new($stdout))
          @service_name = service_name
          @config = config
          @logger = logger
        end

        # Start the event manager
        def start; end

        # Stop the event manager
        def stop; end

        # Publish an event which happened to a specific resource.
        # @param resource [String] The resource related to the event.
        # This is useful to ensure ordering of events.
        # @param resource_type [String] The resource type/class
        # @param resource_id [String] The resource id
        # @param event [String] The event type
        # @param payload [Hash] The payload content of the event
        # @param headers [Hash] The headers of the message (if any)
        # @param reply_to [String] The channel to send the response to if any
        def publish_resource_event(resource_type:, resource_id:, event:, payload:, headers: {})
          # :nocov:
          raise NotImplementedError, "please implement publish_resource_event"
          # :nocov:
        end

        # Publish a message to a channel
        # @param channel [String] The channel to publish to
        # @param payload [Hash] The payload of the message
        # @param headers [Hash] The headers of the message (if any)
        # @param reply_to [String] The channel to send the response to
        def publish(topic, payload, headers: {}, reply_to: nil)
          # :nocov:
          raise NotImplementedError, "please implement publish"
          # :nocov:
        end

        # Send request to a specific topic
        # @param topic [String] The topic to send the request to
        # @param content [Hash] The payload of the request
        # @param headers [Hash] The headers of the message (if any)
        # @param reply_to [String] The topic to send the response to
        # @param timeout [Float] The timeout of the request in second
        # @return Promise<Message> The response of the request
        # @raise [Verse::Error::Timeout] If the request timed out
        def request(topic, content, headers: {}, reply_to: nil, timeout: 0.5)
          # :nocov:
          raise NotImplementedError, "please implement request"
          # :nocov:
        end

        # Send request to multiple subscribers. Wait until timeout and
        # return an array of responses.
        # @param topic [String] The topic to send the request to
        # @param content [Hash] The payload of the request
        # @param headers [Hash] The headers of the message (if any)
        # @param timeout [Float] The timeout of the request
        # @return Promise<[Array<Message>]> The responses of the request
        def request_all(topic, content, headers: {}, reply_to: nil, timeout: 0.5)
          # :nocov:
          raise NotImplementedError, "please implement request_all"
          # :nocov:
        end

        # Subscribe to a specific topic in a specific mode
        # @param topic [String] The topic to subscribe to
        # @param mode [Symbol] The mode of the subscription
        # @param block [Proc] The block to execute when a message is received
        def subscribe(topic, mode: Manager::MODE_CONSUMER, &block)
          # :nocov:
          raise NotImplementedError, "please implement subscribe"
          # :nocov:
        end

        #
        def subscribe_resource_event(resource_type:, event:, mode: Manager::MODE_CONSUMER, &block)
          # :nocov:
          raise NotImplementedError, "please implement subscribe_event"
          # :nocov:
        end
      end
    end
  end
end
