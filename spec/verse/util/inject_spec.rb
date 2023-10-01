# frozen_string_literal: true

module Spec
  module Inject
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
  end
end

RSpec.describe Verse::Util::Inject do
  it "includes the extension module" do
    expect(Spec::Inject::Foo).to respond_to(:foo)
    expect(Spec::Inject::Foo.foo).to eq "bar"
  end
end
