# frozen_string_literal: true

class TestService < Verse::Service::Base
  use_repo users: UserRepository

  def some_action
    users.index({})
  end
end
