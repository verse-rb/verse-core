# frozen_string_literal: true

class DummyEventManager
  @channels = {}

  class << self
    attr_reader :channels

    def clear
      channels.clear
    end
  end

  def publish(channel, payload, **_opts)
    self.class.channels[channel] ||= []
    self.class.channels[channel] << payload
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def publish_resource_event(resource_type:, resource_id:, event:, payload:, headers:, reply_to:)
    channel = [resource_type, event]
    publish(channel, payload)
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
