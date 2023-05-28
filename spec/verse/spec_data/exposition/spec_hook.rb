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

      ctx = Verse::Auth::Context[:system]

      exposition = create_exposition(
        ctx,
        context: "This is some contextual information",
        some_data: @some_data,
        params: params
      )

      method = @method
      metablock = @metablock

      exposition.run do
        output = method.bind(self).call
        metablock.process_output(output)
      end
    end
  end
end
