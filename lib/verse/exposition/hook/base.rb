# frozen_string_literal: true

module Verse
  module Exposition
    module Hook
      class Base
        extend ClassMethods

        attr_reader :exposition_class, :method, :metablock

        def initialize(exposition_class)
          @exposition_class = exposition_class
        end

        # Create exposition instance
        # @param auth_context [Verse::Iam::AuthContext]
        #        The context of authorization to pass to the exposition.
        # @param opts [Hash] A hash used to create custom accessor to the newly created exposition.
        # @return [Verse::Exposition::Base+] Instance of the exposition
        def create_exposition(
          auth_context, **opts
        )
          @exposition_class.new(
            auth_context,
            @method.original_name,
            self,
            **opts
          )
        end

        def register(method, metablock)
          @metablock = metablock
          @method = method

          register_impl
        end

        def register_impl
          raise NotImplementedError, "register_impl must be implemented"
        end
      end
    end
  end
end
