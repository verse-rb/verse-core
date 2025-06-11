# frozen_string_literal: true

require_relative "./base"

module Verse
  module Exposition
    module Hook
      # This type of exposition listen to the event bus
      class EventBus < Base
        attr_reader :method, :channel, :resource_channel, :type

        # @param exposition [Verse::Exposition::Base] The exposition instance
        # @param channels [Array<String>] The list of channels to listen to
        # @param type [Symbol] The type of listener. `:broadcast`, `:consumer` or `:command`
        def initialize(exposition,
                       channel: nil,
                       resource_channel: nil,
                       type: Verse::Event::Manager::MODE_CONSUMER,
                       ack: :on_receive,
                       **opts)
          super(exposition)

          @type = type
          @opts = opts
          @ack = ack

          @channel = channel
          @resource_channel = resource_channel
        end

        # @return [Array<String>] The list of channels to listen to,
        #   with the service name prepended when the type is command
        #   unless absolute_path is set to true
        def channel_path
          if !@channel || type != Verse::Event::Manager::MODE_COMMAND || @opts[:absolute_path]
            return @channel
          end

          [Verse.service_name, @channel].join(".")
        end

        # r command output to publish in the reply channel
        def create_output_message(topic, output, is_error:)
          if is_error
            [{
              topic:,
              error: {
                type: output.class.name,
                message: output.message,
                details: output.respond_to?(:details) ? output.details : nil,
                source: output.respond_to?(:source) ? output.source : nil
              }
            },
             {
               content: "reply:error"
             }]
          else
            [
              {
                topic:,
                output:
              },
              {
                content: "reply:output"
              }
            ]
          end
        end

        def allow_reply?
          Verse::Event::Manager::MODE_COMMAND && !@opts[:no_reply]
        end

        def auth_context_for(_message)
          Verse::Auth::Context[:system]
        end

        def register_impl
          if Verse.event_manager.nil?
            Verse.logger&.warn{ "Your service doesn't have event manager setup. Exposition linked to events won't be registered." }
            return false
          end

          code = ->(message, subject) do
            Verse.logger&.debug{ "Received event from `#{subject}`" }

            output = nil

            begin
              method = @method
              metablock = @metablock

              safe_params = metablock.process_input(message.content)

              exposition = create_exposition(
                auth_context_for(message),
                message:,
                reply_to: message.reply_to,
                subject:,
                params: safe_params,
                metadata: {}
              )

              output = exposition.run do
                auth_context.mark_as_checked!

                metablock.process_output(
                  method.bind(self).call
                )
              end
            rescue StandardError => e
              Verse.logger&.warn{ "Error while processing for method at #{@method.source_location.join(":")}" }
              Verse.logger&.warn(e)

              is_error = true
              output = e
            end

            if allow_reply? && message.allow_reply?
              out, headers = create_output_message(
                subject, output, is_error:
              )

              Verse.logger&.debug{ "Reply to #{message.reply_to}" }
              message.reply(
                out, headers:
              )
            end

            raise output if is_error

            output
          end

          cp = channel_path

          if cp
            Verse.event_manager.subscribe(topic: channel_path, mode: @type, &code)
          end

          return unless resource_channel

          Verse.event_manager.subscribe_resource_event(
            resource_type: resource_channel[0],
            event: resource_channel[1],
            mode: @type, &code
          )
        end
      end
    end
  end
end
