# frozen_string_literal: true

require_relative "./helpers/service_helper"

module Verse
  module Spec
    @users = {}

    class << self
      def add_user(name, role, user_context = {}, scopes = {})
        @users[name] = {
          role: role,
          user_context: user_context,
          scopes: scopes
        }
      end

      def [](name)
        @users[name]
      end
    end

  end
end

RSpec.configure do |c|
  c.include Verse::Spec::ServiceHelper, type: :service
  c.include Verse::Spec::ContextHelper, :as
end
