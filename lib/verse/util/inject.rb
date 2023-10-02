# frozen_string_literal: true

module Verse
  module Util
    module Inject
      # Injects a module into the current object, this works like running
      # a macro on the current object, but has the ability to pass arguments
      # to the call.
      #
      # The module inject must have a `call` method; different arguments
      # can be passed to the `call` method by passing them as keyword arguments
      #
      # @example
      #
      #   module BarFeature
      #     def call(module, name:)
      #       module.define_singleton_method(name) do
      #         "bar" # define a new method on the receiver of the injection
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     extend Verse::Util::Inject
      #
      #     inject BarFeature, name: :foo
      #   end
      #
      #   Foo.foo # => "bar"
      #
      #
      # @param mod [Module] the module to include
      # @param opts [Hash] the arguments to pass to the module's `call` method
      #
      def inject(mod, **opts)
        mod.instance_method(:call).bind(mod).call(self, **opts)
      end
    end
  end
end
