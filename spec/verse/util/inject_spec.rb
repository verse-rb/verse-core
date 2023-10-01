RSpec.describe Verse::Util::Inject do
  module BarFeature
    def call(name:)
      define_singleton_method(name) do
        "bar"
      end
    end
  end

  module Foo
    extend Verse::Util::Inject

    inject BarFeature, name: :foo
  end


  it "includes the extension module" do
    expect(Foo).to respond_to(:foo)
    expect(Foo.foo).to eq "bar"
  end
end