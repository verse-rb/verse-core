# frozen_string_literal: true

RSpec.describe Verse::Util::AutovalidatedEndpoint do
  subject do
    Class.new{ include Verse::Util::AutovalidatedEndpoint }.new
  end

  it "saves and show description" do
    expect(subject.desc).to be_nil
    subject.desc("This is a test")
    expect(subject.desc).to eq("This is a test")
  end

  context "#input" do
    it "can process input (passing a schema)" do
      schema = Dry::Schema.Params do
        required(:name).filled
      end

      subject.input(schema)

      expect(subject.process_input(name: "John")).to eq({ name: "John" })
    end

    it "can process input (passing a block)" do
      subject.input do
        required(:name).filled
      end

      expect(subject.process_input(name: "John")).to eq({ name: "John" })
    end

    it "raises an error if both schema and block are given" do
      schema = Dry::Schema.Params do
        required(:name).filled
      end

      expect{
        subject.input(schema) do
          required(:name).filled
        end
      }.to raise_error(ArgumentError)
    end

    it "raises an error if no schema or block are given" do
      expect{
        subject.input
      }.to raise_error(ArgumentError)
    end

    it "raise validation error if the schema is incorrect" do
      subject.input do
        required(:name).filled
      end

      expect{
        subject.process_input(name: nil)
      }.to raise_error(Verse::Error::ValidationFailed)
    end
  end

  context "#output" do
    it "can process output (passing a schema)" do
      schema = Dry::Schema.Params do
        required(:name).filled
      end

      subject.output(schema)

      expect(subject.process_output(name: "John")).to eq({ name: "John" })
    end

    it "can process output (passing a block)" do
      subject.output do
        required(:name).filled
      end

      expect(subject.process_output(name: "John")).to eq({ name: "John" })
    end

    it "raises an error if both schema and block are given" do
      schema = Verse::Schema.define do
        field(:name, String)
      end

      expect{
        subject.output(schema) do
          field(:name, String)
        end
      }.to raise_error(ArgumentError)
    end

    it "raises an error if no schema or block are given" do
      expect{
        subject.output
      }.to raise_error(ArgumentError)
    end

    it "raise validation error if the schema is incorrect" do
      subject.output do
        field(:name, Object).filled
      end

      expect{
        subject.process_output(name: nil)
      }.to raise_error(Verse::Error::ValidationFailed)
    end
  end
end
