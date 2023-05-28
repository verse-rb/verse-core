# frozen_string_literal: true

module Handlers
  @calls = []
  class << self
    attr_reader :calls

    def call(arg)
      @calls << arg
    end

    def clear
      @calls.clear
    end
  end

  class SampleHandler1 < Verse::Exposition::Handler
    def call
      Handlers.call("SampleHandler1")
      call_next
    end
  end

  class SampleHandler2 < Verse::Exposition::Handler
    def call
      Handlers.call(opts)
      call_next
    end
  end

  class SampleHandler3 < Verse::Exposition::Handler
    def call
      Handlers.call("SampleHandler3")
      call_next
    end
  end
end
