# frozen_string_literal: true

module Verse
  module Spec
    module Auth
      # Use this class to mock an auth context for testing purposes.
      # Actions follow the format `["resource.action.scope"]`.
      #
      # Special wildcard `*` can be used for all resources, actions or scopes.
      # Special wildcard `?` can be used for custom scopes.
      #
      # @example
      #
      #   MockAuthContext.new(["users.read.*", "users.write.?"])
      #   # means that the user can read all users and write custom users
      #   # with custom value found in `context[:users]` key.
      #
      # @see Verse::Auth::Context
      class MockContext < Verse::Auth::Context
        @roles = {}

        attr_accessor :user_id, :user_role

        def self.all_access
          MockContext.new(["*.*.*"])
        end

        def self.no_access
          MockContext.new([])
        end

        # Use this class to mock an auth context for testing purposes.
        #
        # @param rights [Array] The list of rights allowed for this context.
        #        Follow the format `["resource.action.scope"]`.
        #        Wildcard `*` for all resources, actions or scopes.
        #        Wildcard `?` for custom scopes.
        # @param role [String] simulate a role name
        # @param id [Integer] simulate a user id
        #
        # Example:
        #
        # ```
        # MockAuthContext.new(["users.read.*", "users.write.?"])
        # ```
        #
        def initialize(rights = ["*.*.*"], data: {}, role: "test", id: 1)
          super()

          @data.merge!(data.transform_keys(&:to_sym))

          generate_rights(rights)

          @user_role = role
          @user_id   = id
        end

        protected def generate_rights(rights)
          @rights = rights.map{ |x|
            resource, action, scope = x.split(/\./)

            Verse::Util::Assertion.assert(resource && action && scope) do
              "string must be in the format `[resource].[action].[scope]`"
            end

            resource_regexp = Regexp.new(resource.gsub("*", ".*"))
            action_regexp = Regexp.new(action.gsub("*", ".*"))
            scope = scope.gsub("*", "all").gsub(/^\?$/, "custom")

            if scope == "custom"
              raise "custom scope `?` not allowed for wildcard resources" if resource == "*"

              unless self[resource.to_sym]
                raise "custom scope `?` found for resource `#{resource}` but no custom data was given"
              end
            end

            [resource_regexp, action_regexp, scope.to_sym]
          }
        end

        # :nodoc:
        def can?(action, resource)
          resource = resource.to_s
          action = action.to_s

          scope = @rights.find{ |(res, act, _)| res =~ resource && act =~ action }

          (scope && scope[2]) || false
        end
      end
    end
  end
end