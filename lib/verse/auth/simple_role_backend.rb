# frozen_string_literal: true

module Verse
  module Auth
    module SimpleRoleBackend
      @roles = {
        system: ["*.*.*"],
        anonymous: []
      }

      class << self
        attr_reader :roles

        def []=(name, rights)
          @roles[name.to_sym] = rights
        end

        def [](name)
          @roles[name]
        end

        def fetch(rolename)
          @roles.fetch(rolename.to_sym) do
            raise "Role `#{rolename}` not set"
          end
        end
      end
    end
  end
end
