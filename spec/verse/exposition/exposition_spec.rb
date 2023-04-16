# frozen_string_literal: true

require_relative "../spec_data/exposition/expo_class_methods"
require_relative "../spec_data/exposition/spec_hook"

# Add the helpers
Verse::Exposition::ClassMethods.include(
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

  it "run the block on trigger" do
    SampleExposition.output = nil

    SpecHook.trigger_exposition({ name: "John" })

    expect(SampleExposition.output).to eq(
      :context=>"This is some contextual information", :name=>"John Doe", :some_data=>{:data=>true}
    )
  end
end
