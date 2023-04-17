# frozen_string_literal: true

# This is a very bare minimum hook implementation,
# which can be called by `SpecHook.trigger_exposition(input)`
class SpecHook < Verse::Exposition::Hook::Base
  attr_reader :some_data

  @callback = nil

  class << self
    attr_accessor :callback

    def trigger_exposition(input)
      @callback.call(input)
    end
  end

  def initialize(exposition_class, some_data)
    super(exposition_class)
    @some_data = some_data
  end

  def register_impl
    self.class.callback = proc do |input|
      params = @metablock.process_input(input)

      exposition = create_exposition(
        Verse::Auth::Context[:superuser],
        context: "This is some contextual information",
        some_data: @some_data,
        params: params
      )

      method = @method

      output = exposition.run do
        method.bind(self).call
      end

      @metablock.process_output(output)
    end
  end
end
