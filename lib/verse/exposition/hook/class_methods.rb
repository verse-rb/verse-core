module Verse
  module Exposition
    module Hook
      module ClassMethods
        attr_reader :error_handlers

        def inherited(subclass)
          subclass.instance_variable_set(:@error_handlers, [])
        end

        def add_error_handler(&handler)
          @error_handlers << handler

          handler
        end

        def remove_error_handler(handler)
          @error_handlers.reject!{ |x| x == handler }
        end
      end
    end
  end
end