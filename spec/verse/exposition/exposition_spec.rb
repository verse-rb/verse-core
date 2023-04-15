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

  it "can do something" do

  end
end