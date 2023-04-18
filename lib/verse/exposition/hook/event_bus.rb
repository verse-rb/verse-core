# frozen_string_literal: true

require_relative "./base"

module Verse
  module Exposition
    module Hook
      # This type of exposition listen to the event bus
      class EventBus < Base
        attr_reader :method, :channels, :type

        # @param exposition [Verse::Exposition::Base] The exposition instance
        # @param channels [Array<String>] The list of channels to listen to
        # @param type [Symbol] The type of listener. `:broadcast`, `:consumer` or `:command`
        def initialize(exposition, channel, type: Verse::Event::Manager::MODE_CONSUMER, ack_type: :on_receive,  **opts)
          @type = type
          @opts = opts

          @channels = channels.map{ |c|
            [root, c].compact.reject(&:empty?).join(".")
          }.freeze
        end

        # @return [Array<String>] The list of channels to listen to,
        #   with the service name prepended when the type is command
        #   unless absolute_path is set to true
        def channel_path
          if type != Verse::Event::Manager::MODE_COMMAND || @opts[:absolute_path]
            return @channels
          end

          @channels.map{ |c| [Verse.service_name, c].join(".") }
        end

        # r command output to publish in the reply channel
        def create_output_message(topic, output, is_error:)
          if is_error
            {
              topic: topic,
              error: {
                type: output.class.name,
                message: output.message,
                details: output.respond_to?(:details) ? output.details : nil,
                source: output.respond_to?(:source) ? output.source : nil
              }
            }
          else
            {
              topic: topic,
              output: output
            }
          end
        end

        def allow_reply?
          Verse::Event::Manager::MODE_COMMAND && !@opts[:no_reply]
        end

        def register_impl
          if Verse.event_manager.nil?
            Verse.logger.warn{ "Your service doesn't have event manager setup. Exposition linked to events won't be registered." }
            return false
          end

          absolute_channels.each do |c|
            Verse.event_manager.subscribe(c, @type) do |message, reply_to, subject|
              Verse.logger.debug{ "Received event #{subject}"}

              begin
                safe_params = meta.process_input(message.content)

                exposition = create_exposition(
                  auth_context_for(message),
                  message: message,
                  reply: reply,
                  subject: subject,
                  params: safe_params,
                  metadata: {}
                )

                method = @method
                metablock = @metablock

                exposition.run do
                  output = metablock.process_output(
                    method.bind(self).call
                  )
                end
              rescue e
                Verse.logger.warn{ "Error while processing for method at #{block.source_location.join(":")}" }
                Verse.logger.warn(e)

                is_error = true
                output = e
              end

              if allow_reply? && !(reply.nil? || reply.blank?)
                out = create_output_message(
                  subject, output, is_error: is_error
                )

                Verse.logger.debug{ "Reply to #{reply}"}
                Verse.event_manager.publish(
                  reply, out
                )
              end

            end
          end
        end

      end
    end
  end
end
