# frozen_string_literal: true

module Verse
  attr_accessor :event_manager

  def publish(channel, content, headers: {}, reply_to: nil)
    if manager = Verse.event_manager
      manager.publish(
        channel,
        content,
        headers: headers,
        reply_to: reply_to
      )
    else
      Verse.logger.debug{ "[no_em] publish on #{channel} #{content.inspect}" }
    end
  end

  def request(channel, content, headers: {}, reply_to: nil, timeout: 0.5)
    if manager = Verse.event_manager
      manager.request(
        channel,
        content,
        headers: headers,
        reply_to: reply_to,
        timeout: 0.5
      )
    else
      Verse.logger.debug{ "[no_em] request on #{channel} #{content.inspect}" }
    end
  end

  def request_all(channel, content, headers: {}, reply_to: nil, timeout: 0.5)
    if manager = Verse.event_manager
      manager.request_all(
        channel,
        content,
        headers: headers,
        reply_to: reply_to,
        timeout: 0.5
      )
    else
      Verse.logger.debug{ "[no_em] request_all on #{channel} #{content.inspect}" }
    end
  end
end
