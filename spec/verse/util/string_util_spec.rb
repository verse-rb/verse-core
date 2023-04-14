# frozen_string_literal: true

RSpec.describe Verse::Util::StringUtil do
  subject{ Verse::Util::StringUtil }

  it "can convert string to camel case" do
    expect(subject.camelize("test")).to eq("Test")
    expect(subject.camelize("test", false)).to eq("test")
    expect(subject.camelize("test_test")).to eq("TestTest")
    expect(subject.camelize("test_test", false)).to eq("testTest")
    expect(subject.camelize("test_test_test")).to eq("TestTestTest")
    expect(subject.camelize("test_test_test", false)).to eq("testTestTest")
    expect(subject.camelize("test/test")).to eq("Test::Test")
    expect(subject.camelize("test/test", false)).to eq("test::Test")
    expect(subject.camelize("test/test_test")).to eq("Test::TestTest")
    expect(subject.camelize("test/test_test", false)).to eq("test::TestTest")
    expect(subject.camelize("test/test_test_test")).to eq("Test::TestTestTest")
    expect(subject.camelize("test/test_test_test", false)).to eq("test::TestTestTest")
  end
end
