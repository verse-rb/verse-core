# frozen_string_literal: true

module Spec
  module Auth
    class Context
      module ClassMethods
        def add_role(name, rights)
          @roles[name] = rights
        end
      end
    end
  end
end
