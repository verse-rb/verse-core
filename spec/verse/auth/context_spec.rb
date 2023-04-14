require "spec_helper"
require "spec/mock_auth_context"

RSpec.describe Verse::Auth::Context do
  it "scopes correctly" do
    can_method = proc do |context|
      context.can!(:read, :users) do |scope|
        scope.all?{
          [1, 2, 3, 4]
        }
        scope.custom?{ |users| users }
        scope.myself?{ [context.user_id] }

        scope.else?(&:reject!)
      end
    end

    {
      all: [1, 2, 3, 4],
      custom: ["1234"],
      myself: [1]
    }.each do |scope, value|
      context = MockAuthContext.new(scope)
      expect(can_method.call(context)).to eq(value)
    end
  end

  it "rejects correctly" do
    @context = MockAuthContext.new(:reject)

    can_method = proc do |context|
      context.can!(:read, :users) do |scope|
        scope.all?{
          [1, 2, 3, 4]
        }
        scope.custom?{ |users| users }
        scope.myself?{ [context.user_id] }

        scope.else?(&:reject!)
      end
    end

    expect do
      can_method.call(@context)
    end.to raise_error(Verse::Auth::Context::UnauthorizedError)
  end
end
