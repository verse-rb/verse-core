require_relative "../data/test_service"
require_relative "../data/mock_auth_context"

RSpec.describe Verse::Service::Base do
  subject { TestService }

  it "can be initialized" do
    expect do
      subject.new(MockAuthContext.new(:all))
    end.not_to raise_error
  end

  it "set metadata" do
    service = subject.new(MockAuthContext.new(:all), { foo: "bar" })
    expect(service.metadata).to eq({ foo: "bar" })
  end

  it "has block with_metadata" do
    service = subject.new(MockAuthContext.new(:all), { test: "test" })

    service.with_metadata(foo: "bar") do
      expect(service.metadata).to eq({ test: "test", foo: "bar" })
    end

    expect(service.metadata).to eq({ test: "test" })
  end
end
