# frozen_string_literal: true

class SampleExposition < Verse::Exposition::Base
  @something_done = false

  class << self
    attr_reader :something_done
  end

  expose on_spec_hook({ data: true }) do
    input do
      required(:name).filled(:string)
    end
  end
  def do_something
    @something_done = true
  end
end
