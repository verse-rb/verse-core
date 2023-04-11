# frozen_string_literal: true

RSpec.describe Verse::Util::Reflection do
  subject { Verse::Util::Reflection }
  it "can get the class from a string" do
    expect(subject.get("String")).to eq(String)
    expect(subject.get("::String")).to eq(String)
    expect(subject.get("Verse::Plugin")).to eq(Verse::Plugin)
    expect(subject.get("::Verse::Plugin")).to eq(Verse::Plugin)

    expect do
      subject.get("::Verse::DoesntExists")
    end.to raise_error(NameError)
  end
end