# frozen_string_literal: true

require_relative "./helpers/service_helper"
require_relative "./helpers/auth_context_helper"

module Verse
  module Spec
    @users = {}

    class << self
      attr_reader :users

      def add_user(name, role, user_data: {}, scopes: {})
        @users[name.to_sym] = {
          role:,
          user_data:,
          scopes:
        }
      end

      def [](name)
        @users[name]
      end
    end
  end
end

RSpec.configure do |c|
  c.include Verse::Spec::AsUserHelper
  c.include Verse::Spec::ServiceHelper, type: :service
  c.include Verse::Spec::AuthContextHelper, :as
end
