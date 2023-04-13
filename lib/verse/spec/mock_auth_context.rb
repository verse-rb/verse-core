# frozen_string_literal: true

class MockAuthContext < Verse::Auth::Context

  attr_accessor :user_id
  attr_accessor :user_role

  # Use this class to mock an auth context for testing purposes.
  #
  # @param authorization [Hash|:all] A hash of resource/action pairs to be used
  #                                  as the authorization. You can pass the
  #                                  symbol `:all` to allow all actions on all
  #                                  resources (admin/bypass mode).
  #
  # Example:
  #
  # ```
  #  MockAuthContext.new(users: {read: :all, write: :myself}, posts: {read: :all, write: :custom})
  # ```
  #
  def initialize(hash_or_symbol)
    super()

    case hash_or_symbol
    when Hash
      @authorization = hash_or_symbol
    when :all
      @authorization = :all
    else
      raise ArgumentError, "Must pass a hash or :all"
    end

    @role = "test"
    @id   = 1
  end

  # :nodoc:
  def can?(action, resource)
    return :all if @authorization == :all
    return @authorization.fetch(resource, false).fetch(action, false)
  end

  # :nodoc:
  def list_scopes(action, resource)
    @scopes[resource]
  end
end