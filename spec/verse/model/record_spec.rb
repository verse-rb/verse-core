require_relative "../spec_data/model/post_record"

RSpec.describe Verse::Model::Record::Base do
  let(:subject) {
    PostRecord
  }


  it "self.primary_key" do
    expect(PostRecord.primary_key).to eq(:id)
  end

  it "#new" do
    record = subject.new({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World"
    })

    expect(record.id).to eq(1)
    expect(record.user_id).to eq(1)
    expect(record.title).to eq("Hello")
    expect(record.content).to eq("World")
    expect(record.secret_field).to eq(nil)

    expect(record["content"]).to eq("World")
  end

  it "#to_h" do
    record = subject.new({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World",
      secret_field: "Foo Bar"
    })

    expect(record.to_h).to eq({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World",
      secret_field: "Foo Bar"
    })

    expect(record.to_h(true)).to eq({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World"
    })
  end

  it "type" do
    record = subject.new({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World",
      secret_field: "Foo Bar"
    })

    expect(record.type).to eq("posts")
  end

  it "#to_json" do
    record = subject.new({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World",
      secret_field: "Foo Bar"
    })

    expect(record.to_json).to eq({
      id: 1,
      user_id: 1,
      title: "Hello",
      content: "World"
    }.to_json)
  end


end
