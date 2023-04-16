# frozen_string_literal: true

module Verse
  attr_accessor :event_manager

  def publish(event_path, payload)
    if manager = Verse.event_manager
      manager.publish(event_path, payload)
    else
      Verse.logger.debug{ "[no_em] publish on #{event_path} #{payload.inspect}" }
    end
  end
end
