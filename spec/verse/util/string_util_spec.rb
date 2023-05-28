# frozen_string_literal: true

RSpec.describe Verse::Util::StringUtil do
  subject{ Verse::Util::StringUtil }

  it "can convert string to camel case" do
    expect(subject.camelize("test")).to eq("Test")
    expect(subject.camelize("test", uppercase_first_letter: false)).to eq("test")
    expect(subject.camelize("test_test")).to eq("TestTest")
    expect(subject.camelize("test_test", uppercase_first_letter: false)).to eq("testTest")
    expect(subject.camelize("test_test_test")).to eq("TestTestTest")
    expect(subject.camelize("test_test_test", uppercase_first_letter: false)).to eq("testTestTest")
    expect(subject.camelize("test/test")).to eq("Test::Test")
    expect(subject.camelize("test/test", uppercase_first_letter: false)).to eq("test::Test")
    expect(subject.camelize("test/test_test")).to eq("Test::TestTest")
    expect(subject.camelize("test/test_test", uppercase_first_letter: false)).to eq("test::TestTest")
    expect(subject.camelize("test/test_test_test")).to eq("Test::TestTestTest")
    expect(subject.camelize("test/test_test_test", uppercase_first_letter: false)).to eq("test::TestTestTest")
  end

  it "can convert string to snake case" do
    expect(subject.underscore("Test")).to eq("test")
    expect(subject.underscore("TestTest")).to eq("test_test")
    expect(subject.underscore("TestTestTest")).to eq("test_test_test")
    expect(subject.underscore("Test::Test")).to eq("test/test")
    expect(subject.underscore("Test::TestTest")).to eq("test/test_test")
    expect(subject.underscore("Test::TestTestTest")).to eq("test/test_test_test")
  end
end
