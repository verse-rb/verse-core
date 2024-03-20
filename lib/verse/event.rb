# frozen_string_literal: true

module Verse
  attr_accessor :event_manager

  def publish(topic, payload, headers: {}, reply_to: nil)
    if manager = Verse.event_manager
      manager.publish(
        topic,
        payload,
        headers:,
        reply_to:
      )
    else
      Verse.logger.debug{ "[no_em] publish on #{topic} (#{payload.size} bytes)" }
    end
  end

  def publish_resource_event(resource_type:, resource_id:, event:, payload:, headers: {})
    if manager = Verse.event_manager
      manager.publish_resource_event(resource_type:, resource_id:, event:, payload:, headers:)
    else
      # :nocov:
      Verse.logger.debug{ "[no_em] publish_event on #{resource_type}:#{resource_id}##{event} (#{payload.size} bytes)" }
      # :nocov:
    end
  end

  def request(channel, content = {}, headers: {}, reply_to: nil, timeout: 0.5)
    if manager = Verse.event_manager
      manager.request(
        channel,
        content,
        headers:,
        reply_to:,
        timeout:
      )
    else
      # :nocov:
      Verse.logger.debug{ "[no_em] request on #{channel} (#{content.size} bytes)" }
      # :nocov:
    end
  end

  def request_all(channel, content = {}, headers: {}, reply_to: nil, timeout: 0.5)
    if manager = Verse.event_manager
      manager.request_all(
        channel,
        content,
        headers:,
        reply_to:,
        timeout:
      )
    else
      # :nocov:
      Verse.logger.debug{ "[no_em] request_all on #{channel} (#{content.inspect} bytes)" }
      # :nocov:
    end
  end
end
