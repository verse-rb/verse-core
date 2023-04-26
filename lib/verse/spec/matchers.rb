RSpec::Matchers.define :receive_event do |channel|
  chain :with_content do |data|
    @content = data
  end

  match do |proc|
    sub = Verse.event_manager.subscribe(channel) do |message, _subject|
      @received = message
    end

    proc.call

    if @content
      @received&.content == @content
    else
      @received
    end
  ensure
    sub.unsubscribe
  end

  error_message do
    err = "expected block to receive event `#{channel}`"
    if @content
      err << " with content `#{@content}`"
    end
  end
end

