require_relative "./class_methods"

module Verse
  module Exposition
    class Base
      extend ClassMethods

      attr_reader :auth_context, :current_action, :hook

      @handlers = []

      def initialize(auth_context, action, hook, **fields)
        @auth_context = auth_context
        @current_action = action

        fields.each do |key, value|
          raise "cannot redefine method `#{key}`" if key.methods.include?(key)

          define_singleton_method(key) { value }
        end
      end

      def service
        if self.class.service_class
          @service ||= self.class.service_class.new(auth_context)
        else
          nil
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
          previous_handler = handler_class.new(previous_handler, self, **opts)
        end

        previous_handler
      end


    end
  end
end
