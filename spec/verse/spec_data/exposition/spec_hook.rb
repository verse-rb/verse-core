# frozen_string_literal: true

# This is a very bare minimum hook implementation,
# which can be called by `SpecHook.trigger_exposition(input)`
class SpecHook < Verse::Exposition::Hook::Base
  attr_reader :some_data

  @callback = nil
  @hooks = []

  class << self
    attr_accessor :callback, :hooks

    def trigger(method_name, input)
      hooks.find{ |hook| hook.method.name == method_name }.trigger(input)
    end
  end

  def initialize(exposition_class, some_data)
    super(exposition_class)
    @some_data = some_data

    self.class.hooks << self
  end

  def trigger(input)
    @callback.call(input)
  end

  def register_impl
    @callback = proc do |input|
      params = @metablock.process_input(input)

      ctx = Verse::Auth::Context[:system]

      exposition = create_exposition(
        ctx,
        context: "This is some contextual information",
        some_data: @some_data,
        params:
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
