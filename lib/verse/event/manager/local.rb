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

        def initialize(service_name, config = nil, logger = Logger.new($stdout))
          super

          @subscriptions = {}
        end

        def subscribe(
          channel,
          _method = Manager::MODE_CONSUMER,
          priority: nil, # rubocop:disable Lint/UnusedMethodArgument
          ack_type: nil, # rubocop:disable Lint/UnusedMethodArgument
          &block
        )
          return if @config&.fetch(:disable_subscription, nil)

          regexp = Regexp.new(
            "^#{channel.gsub(".", "\\.").gsub("?", "[^\.]+").gsub("*", ".*")}$"
          )

          add_to_subscription_list(regexp) do |message, subject|
            block.call(message, subject)
          end
        end

        def start
          puts "start?"
        end

        def stop
          @subscriptions.clear
        end

        def request(channel, content, headers: {}, reply_to: nil, timeout: 0.05)
          reply_to ||= "_reply.#{SecureRandom.hex}"

          out = nil

          subscription = subscribe(reply_to) do |message|
            subscription.unsubscribe # Remove the subscription once a message is caught.
            out = message
          end

          Timeout.timeout(timeout) do
            message = Message.new(self, content, headers: headers, reply_to: reply_to)

            @subscriptions.each do |pattern, subscribers|
              next unless pattern.match?(channel)

              sub = subscribers.first

              puts "found: #{sub.inspect}"

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
          body: {},
          headers: {},
          reply_to: nil, # rubocop:disable Lint/UnusedMethodArgument
          timeout: 0.5
        )
          # Fake request all behavior
          begin
            out = []
            Timeout.timeout(timeout) do
              out << request(channel, body: body, headers: headers, timeout: timeout)
              sleep
            end
          rescue Timeout::Error
            # Do nothing, we always timeout; same behavior into NATS EM
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
        def publish(channel, content, headers: {}, reply_to: nil)
          message = Message.new(self, content, headers: headers, reply_to: reply_to)

          @subscriptions.each do |pattern, subscribers|
            next unless pattern.match?(channel)

            subscribers.each do |s|
              s.call(message, channel)
            end
          end
        end

        def cancel_subscription(id)
          @subscriptions.each do |_, subscribers|
            subscribers.reject! { |sub| sub.id == id }
          end
        end

        private

        def add_to_subscription_list(regexp, &block)
          sub = Subscription.new(self, self.class.sub_id, block)
          @subscriptions[regexp] ||= []
          @subscriptions[regexp] << sub
          sub
        end
      end
    end
  end
end
