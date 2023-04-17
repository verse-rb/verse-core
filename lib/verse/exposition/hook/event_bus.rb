# frozen_string_literal: true

require_relative "./base"

module Verse
  module Exposition
    module Hook
      # This type of exposition listen to the event bus
      class EventBus < Base
        attr_reader :method, :channels, :type

        def initialize(exposition, channels, type: :jetstream, **opts)
          root = exposition.event_path || ""

          @type = type
          @opts = opts

          @channels = channels.map{ |c|
            [root, c].compact.reject(&:empty?).join(".")
          }.freeze
        end

        def render_output(path, output, metadata, is_error:)
          if is_error
            {
              path: path,
              metadata: metadata,
              error: {
                type: output.class.name,
                message: output.message,
                details: output.respond_to?(:details) ? output.details : nil,
                source: output.respond_to?(:source) ? output.source : nil
              }
            }.to_json
          else
            {
              path: path,
              metadata: metadata,
              result: output
            }.to_json
          end
        end

        def absolute_channels
          if type == :command && !@opts[:absolute_path]
            @channels.map{ |c| [EFrame.service_name, c].join(".") }
          else
            @channels
          end
        end

        def register(exposition_class, block, meta)
          method = @method
          expo_method_name = block.original_name
          hook = self

          if EFrame.event_manager.nil?
            EFrame.logger.warn{ "Your service doesn't have event manager setup. Exposition linked to events won't be registered." }
            return false
          end

          absolute_channels.each do |c|
            EFrame.event_manager.subscribe(c, @type) do |message, reply, subject|
              EFrame.logger.debug{ "Received event #{subject}"}

              message = message.deep_symbolize_keys

              begin
                safe_params = meta.process_input(message)

                exposition = exposition_class.new(EFrame::Iam.system_context,
                  expo_method_name,
                  hook,
                  unsafe_message: message,
                  reply: reply,
                  subject: subject,
                  params: safe_params,
                  metadata: {}
                )

                output = nil
                is_error = false

                exposition.run do
                  method_name = "#{exposition_class.name}##{block.original_name}"
                  EFrame.logger.info{ "CALL #{method_name} on #{subject}" }

                  metadata = service&.metadata
                  metadata[:expo] = method_name if metadata

                  output = block.bind(self).call
                end
              rescue RuntimeError => e
                EFrame.logger.warn{ "Error while processing for method at #{block.source_location.join(":")}" }
                EFrame.logger.warn(e)

                is_error = true
                output = e

                self.class.error_handlers.each do |handler|
                  handler.call(e)
                end
              end

              if @type == :command && !reply.empty?
                output = EFrame::Model::Serializer::JsonApiRenderer.new.render(output)

                out = render_output(
                  subject, output, {}, is_error: is_error
                )

                EFrame.logger.debug{ "reply to #{reply}"}
                EFrame.event_manager.publish(
                  reply, out
                )
              end

              # reraise the error after notifying the requester (if any)
              # raise output if is_error
            end
          end
        end

      end
    end
  end
end
