# frozen_string_literal: true

require_relative "./base"

module Verse
  module Event
    module Manager
      # This is a simplified event manager for test environment,
      # it run locally (in the process) and cannot communicate with other services.
      class Local < Base
        attr_reader :subscriptions

        @sub_id = 0

        Manager.add_event_manager_type(:local, self)

        class << self
          attr_accessor :sub_id
        end

        Subscription = Struct.new(:manager, :id, :block) do
          def unsubscribe
            manager.cancel_subscription(id)
          end

          def call(message, channel)
            block.call(message, channel)
          end
        end

        def initialize(service_name:, service_id:, config: nil, logger: Logger.new($stdout))
          super

          @subscriptions = {}
        end

        def subscribe(
          topic:,
          mode: Manager::MODE_CONSUMER, # rubocop:disable Lint/UnusedMethodArgument
          &block
        )
          logger.debug{ "Subscribe to #{topic}" }
          return if @config&.fetch(:disable_subscription, nil)

          add_to_subscription_list(topic, &block)
        end

        def subscribe_resource_event(resource_type:, event:, mode: Manager::MODE_CONSUMER, &block)
          logger.debug{ "Subscribe to resource event #{resource_type} #{event}" }
          subscribe(topic: [resource_type, event], mode:, &block)
        end

        def start
          logger.debug{ "Start with local event manager" }
        end

        def stop
          logger.debug{ "Stop local event manager" }
          @subscriptions.clear
        end

        # @overload request(channel, content, headers: {}, reply_to: nil, timeout: 0.05)
        def request(channel, content, headers: {}, reply_to: nil, timeout: 0.05)
          logger.debug{ "Request to #{channel}" }

          reply_to ||= "_reply.#{SecureRandom.hex}"

          out = nil

          subscription = subscribe(topic: reply_to) do |message|
            subscription.unsubscribe # Remove the subscription once a message is caught.
            out = message
          end

          Timeout.timeout(timeout) do
            message = Message.new(content, manager: self, headers:, reply_to:)

            @subscriptions.each do |pattern, subscribers|
              next unless pattern.match?(channel)

              sub = subscribers.first

              if sub
                sub.call(message, channel)
                return out
              end
            end

            raise Timeout::Error # pretend we timed out.
          end
        end

        def request_all(
          channel,
          content,
          headers: {},
          reply_to: nil, # rubocop:disable Lint/UnusedMethodArgument
          timeout: 0.5
        )
          logger.debug{ "Request all to #{channel}" }

          # Fake request all behavior
          begin
            out = []
            Timeout.timeout(timeout) do
              out << request(channel, content, headers:, timeout:)
              sleep
            end
          rescue Timeout::Error
            # Do nothing, we always timeout;
          end

          # Return array with one item only,
          # or empty array if nothing reply to this message.
          out
        end

        # Publish a message to a specific channel
        #
        # @param channel [String] The channel to publish to
        # @param body [Hash] The payload of the message
        # @param headers [Hash] The headers of the message (if any)
        # @param reply_to [String] The reply_to of the message (if any)
        def publish(channel, payload, headers: {}, reply_to: nil)
          logger.debug{ "Publish on #{channel}" }

          message = Message.new(payload, manager: self, headers:, reply_to:)

          @subscriptions.lazy.select{ |chan, _| channel == chan }.map(&:last).each do |sub|
            sub.each{ |s| s.call(message, channel) }
          end
        end

        # rubocop:disable Lint/UnusedMethodArgument
        def publish_resource_event(resource_type:, resource_id:, event:, payload:, headers: {})
          logger.debug{ "Publish resource event #{resource_type} #{event}" }

          headers = headers.merge(event:)
          message = Message.new(payload, manager: self, headers:)
          channel = [resource_type, event]

          @subscriptions.lazy.select{ |chan, _| channel == chan }.map(&:last).each do |sub|
            sub.each{ |s| s.call(message, channel) }
          end
        end
        # rubocop:enable Lint/UnusedMethodArgument

        def cancel_subscription(id)
          @subscriptions.each_value do |subscribers|
            subscribers.reject! { |sub| sub.id == id }
          end
        end

        private

        def add_to_subscription_list(channel, &block)
          sub = Subscription.new(self, self.class.sub_id, block)
          @subscriptions[channel] ||= []
          @subscriptions[channel] << sub
          sub
        end
      end
    end
  end
end
