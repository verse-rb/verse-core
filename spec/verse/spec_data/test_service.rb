# frozen_string_literal: true

require_relative "./model/user_repository"

class TestService < Verse::Service::Base
  use_repo users: UserRepository

  def some_action
    users.index({})
  end
end
