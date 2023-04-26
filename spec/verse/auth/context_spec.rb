# frozen_string_literal: true

require "spec_helper"

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
          scope.myself?{ [context.metadata[:user_id]] }

          scope.else?(&:reject!)
        end
      end

      context = Verse::Auth::Context.new(
        right,
        custom_scopes: { users: ["1234"] },
        metadata: { user_id: 1 }
      )
      expect(can_method.call(context)).to eq(value)
    end
  end

  context "roles" do
    it "has superadmin role" do
      auth = Verse::Auth::Context[:system]
      expect(auth.can?(:read, :users)).to eq(:all)
      expect(auth.can?(:read, :posts)).to eq(:all)
    end

    it "has no access role" do
      auth = Verse::Auth::Context[:anonymous]
      expect(auth.can?(:read, :users)).to eq(false)
      expect(auth.can?(:read, :posts)).to eq(false)
    end

    it "can create custom role" do
      Verse::Auth::Context[:test] = ["users.*.*"]

      auth = Verse::Auth::Context[:test]
      expect(auth.can?(:read, :users)).to eq(:all)
      expect(auth.can?(:read, :posts)).to eq(false)
    end
  end

  it "rejects correctly" do
    # Zero rights.
    @context = Verse::Auth::Context.new([])

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
    end.to raise_error(Verse::Error::Unauthorized)
  end
end
