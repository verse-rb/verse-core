# frozen_string_literal: true

module Verse
  module Exposition
    module ClassMethods
      attr_reader :exposed_endpoints

      def all_expositions
        @all_expositions ||= []
      end

      # Set or return the description for this exposition.
      # Used to generate documentations.
      def desc(value = nil)
        if value
          @desc = value
        else
          @desc
        end
      end

      # Create helper method to use a specific service.
      # @example
      #  class MyExposition < Verse::Exposition::Base
      #     use_service user_service: UserService
      #
      #     def do_something
      #       user_service.do_something
      #     end
      #  end
      #
      # @param service_hash [Hash] A hash of service name and service class.
      #        passing a class instead of hash is equivalent to passing
      #        `{ service: service_class }` as parameter.
      def use_service(service_hash)
        case service_hash
        when Hash
          service_hash.each do |service_name, service_class|
            define_method(service_name) do
              service = instance_variable_get("@#{service_name}")

              return service if service

              service = service_class.new(auth_context, expo: self.class.name)
              instance_variable_set("@#{service_name}", service)

              service
            end
          end
        else
          use_service(service: service_hash)
        end
      end

      def expose(exposition_type, &block)
        @exposition = build_expose(exposition_type, &block)
      end

      def around(*methods, &block)
        methods.each do |method|
          m = instance_method(method)

          # redefine the method.
          define_method(method) do
            instance_exec(m.bind(self), &block)
          end
        end
      end

      def build_expose(exposition_type, &block)
        {
          type: exposition_type,
          meta: Class.new do
            extend Verse::Util::AutovalidatedEndpoint
            instance_eval(&block) if block
          end
        }
      end

      def attach_exposition(method, exposition_hash)
        base_method = instance_method(method)

        @exposed_endpoints[method] = exposition_hash

        Verse.on_boot do
          exposition_hash[:type].register(base_method, exposition_hash[:meta])
        end
      end

      # :nodoc:
      def method_added(method_name)
        super

        return unless @exposition

        begin
          @endpoints ||= []
          @endpoints << [method_name, @exposition]
        ensure
          @exposition = nil
        end
      end

      # Register all exposed endpoints.
      #
      # This must be called manually on initialization:
      #
      # @example
      #   # in file initializers/routes.rb
      #   MyExposition.register
      #
      #
      # This method can be redefined to attach exposition at runtime.
      # This is useful when the exposition rely on data generated
      # at runtime, like Verse.service_id:
      #
      # @example
      #  class MyExposition < Verse::Exposition::Base
      #     def self.register
      #       super
      #       exposition_data = build_expose on_hook(...)
      #       attach_exposition :method_name, exposition_data
      #     end
      #   end
      #
      def register
        @endpoints&.each do |(method_name, exposition)|
          attach_exposition(method_name, exposition)
        end
      end

      # Return all exposition handlers.
      def handlers
        @handlers || superclass.handlers
      end

      # Prepend handler to the handler chain.
      def prepend_handler(klass, **opts)
        @handlers ||= superclass.handlers.dup
        @handlers.prepend([klass, **opts])
      end

      # Append handler at the end of the chain.
      def append_handler(klass, **opts)
        @handlers ||= superclass.handlers.dup
        @handlers << [klass, **opts]
      end

      # Remove a specific handler class from the handler chain.
      def remove_handler(klass)
        @handlers ||= superclass.handlers.dup
        @handlers.reject!{ |x| x.first == klass }
      end

      def clear_handlers
        @handlers&.clear
      end

      def inherited(subklass)
        super

        subklass.instance_eval do
          @desc = nil
          @exposed_endpoints = {}
        end

        Verse::Exposition::Base.all_expositions << subklass
      end
    end
  end
end
