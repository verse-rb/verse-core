class MockAuthContext < Verse::Auth::Context
  def initialize(authorization)
    @authorization = authorization

    @scopes = {
      users: %i<all any myself reject>
    }

    @custom_scopes = {
      users: ["1234"]
    }
  end

  def user_id
    1
  end

  def can?(action, resource)
    return false unless action == :read && resource == :users

    return @authorization
  end

  def list_scopes(action, resource)
    @scopes[resource]
  end
end