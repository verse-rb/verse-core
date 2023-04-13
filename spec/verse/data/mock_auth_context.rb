# frozen_string_literal: true

class MockAuthContext < Verse::Auth::Context
  def initialize(authorization)
    super()

    @authorization = authorization

    @scopes = {
      users: %i<all any myself reject>,
      posts: %i<all any>
    }

    @custom_scopes = {
      users: ["1234"]
    }
  end

  def user_id
    1
  end

  def can?(action, resource)
    return @authorization
  end

  def list_scopes(action, resource)
    @scopes[resource]
  end
end