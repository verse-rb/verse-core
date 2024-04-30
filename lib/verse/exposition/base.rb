# frozen_string_literal: true

require_relative "./class_methods"
require_relative "../util/inject"

module Verse
  module Exposition
    class Base
      extend Verse::Util::Inject
      extend ClassMethods

      attr_reader :auth_context, :current_action, :hook

      @handlers = [Verse::Auth::CheckAuthenticationHandler]

      def initialize(auth_context, action, _hook, **fields)
        @auth_context = auth_context
        @current_action = action

        fields.each do |key, value|
          raise "cannot redefine method `#{key}`" if respond_to?(key)

          define_singleton_method(key) { value }
        end
      end

      def run(&block)
        handler_chain = build_handlers do
          instance_eval(&block)
        end

        handler_chain.call
      end

      private def build_handlers(&block)
        previous_handler = Handler.new(proc{ block.call }, self)
        handlers = self.class.handlers

        handlers.reverse_each do |(handler_class, opts)|
          opts ||= {}
          previous_handler = handler_class.new(previous_handler, self, **opts)
        end

        previous_handler
      end
    end
  end
end
