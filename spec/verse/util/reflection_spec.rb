# frozen_string_literal: true

RSpec.describe Verse::Util::Reflection do
  subject { Verse::Util::Reflection }
  it "can get the class from a string" do
    expect(subject.constantize("String")).to eq(String)
    expect(subject.constantize("::String")).to eq(String)
    expect(subject.constantize("Verse::Plugin")).to eq(Verse::Plugin)
    expect(subject.constantize("::Verse::Plugin")).to eq(Verse::Plugin)

    expect do
      subject.constantize("::Verse::DoesntExists")
    end.to raise_error(NameError)
  end
end
