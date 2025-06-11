# frozen_string_literal: true

require_relative "../spec_data/exposition/expo_class_methods"
require_relative "../spec_data/exposition/spec_hook"
require_relative "../spec_data/exposition/sample_handlers"

# Add the helpers
Verse::Exposition::Base.extend(
  ExpoClassMethods
)

require_relative "../spec_data/exposition/sample_exposition"

RSpec.describe Verse::Exposition do
  before(:all) do
    SampleExposition.register
  end

  before do
    Verse.start(:server, config_path: File.join(__dir__, "../spec_data/config.yml"))
  end

  after do
    Verse.stop
  end

  it "can read the description" do
    expect(SampleExposition.desc).to eq("This is a sample exposition")
  end

  it "run the block on trigger" do
    SampleExposition.output = nil

    SpecHook.trigger(:do_something, { name: "John" })

    expect(SampleExposition.output).to eq(
      context: "This is some contextual information", name: "John Doe", some_data: { data: true }
    )
  end

  it "append handlers" do
    SampleExposition.clear_handlers
    SampleExposition.append_handler(Handlers::SampleHandler1)
    SampleExposition.append_handler(Handlers::SampleHandler2, "hello" => "world")
    SampleExposition.append_handler(Handlers::SampleHandler3)
    Handlers.clear

    SpecHook.trigger(:do_something, { name: "Jane" })

    expect(Handlers.calls).to eq(
      [
        "SampleHandler1",
        { "hello" => "world" },
        "SampleHandler3"
      ]
    )

    SampleExposition.clear_handlers
  end

  it "prepend handlers" do
    SampleExposition.clear_handlers
    SampleExposition.append_handler(Handlers::SampleHandler1)
    SampleExposition.append_handler(Handlers::SampleHandler2, "hello" => "world")
    SampleExposition.prepend_handler(Handlers::SampleHandler3)
    Handlers.clear

    SpecHook.trigger(:do_something, { name: "Jane" })

    expect(Handlers.calls).to eq(
      [
        "SampleHandler3",
        "SampleHandler1",
        { "hello" => "world" }
      ]
    )

    SampleExposition.clear_handlers
  end

  it "raises if the authorization hasn't been checked" do
    SampleExposition.clear_handlers
    SampleExposition.append_handler(
      Verse::Auth::CheckAuthenticationHandler
    )

    SampleExposition.output = nil

    expect do
      SpecHook.trigger(:do_something, { name: "John", mode: :unchecked })
    end.to raise_error(Verse::Error::Authorization)
  end

  it "works with around" do
    SampleExposition.output = nil

    SpecHook.trigger(:test_around_method, { name: "John" })

    expect(SampleExposition.output).to eq("around")
  end
end
