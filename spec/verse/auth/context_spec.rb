# frozen_string_literal: true

require "spec_helper"
require "verse/spec/auth/mock_context"

RSpec.describe Verse::Auth::Context do
  {
    ["*.*.*"] => [1, 2, 3, 4],
    ["users.read.?"] => ["1234"],
    ["users.read.myself"] => [1]
  }.each do |right, value|
    it "scopes correctly for #{right}" do
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

      context = Spec::Auth::MockContext.new(right, data: { users: ["1234"] })
      expect(can_method.call(context)).to eq(value)
    end
  end

  it "rejects correctly" do
    # Zero rights.
    @context = Spec::Auth::MockContext.new([])

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
