# frozen_string_literal: true

require_relative "../spec_data/service/test_service"

RSpec.describe Verse::Service::Base do
  subject { TestService }

  let(:context) {
    Verse::Auth::Context[:superuser]
  }

  it "can be initialized" do
    expect do
      subject.new(context)
    end.not_to raise_error
  end

  it "set metadata" do
    service = subject.new(context, { foo: "bar" })
    expect(service.metadata).to eq({ foo: "bar" })
  end

  it "has block with_metadata" do
    service = subject.new(context, { test: "test" })

    service.with_metadata(foo: "bar") do
      expect(service.metadata).to eq({ test: "test", foo: "bar" })
    end

    expect(service.metadata).to eq({ test: "test" })
  end

  it "can call #some_action" do
    service = subject.new(context)

    UserRepository.clear

    expect(service.some_action).to eq([])
  end
end
