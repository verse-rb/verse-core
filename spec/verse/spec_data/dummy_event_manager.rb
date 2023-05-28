# frozen_string_literal: true

class DummyEventManager
  @channels = {}

  class << self
    attr_reader :channels

    def clear
      channels.clear
    end
  end

  def publish(channel, payload)
    self.class.channels[channel] ||= []
    self.class.channels[channel] << payload
  end
end
