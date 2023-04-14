RSpec.describe Verse::Util::Inflector do
  subject { Verse::Util::Inflector.new }

  it "pluralizes correctly" do
    expect(subject.pluralize("user")).to eq("users")
    expect(subject.pluralize("user", 1)).to eq("user")
    expect(subject.pluralize("user", 2)).to eq("users")

    # exceptions:
    expect(subject.pluralize("person")).to eq("people")
    expect(subject.pluralize("person", 1)).to eq("person")
  end

  it "singularizes correctly" do
    expect(subject.singularize("users")).to eq("user")
    expect(subject.singularize("user")).to eq("user")

    # exceptions:
    expect(subject.singularize("people")).to eq("person")
    expect(subject.singularize("person")).to eq("person")
  end

  it "inflect past tense correctly" do
    expect(subject.inflect_past("create")).to eq("created")
    expect(subject.inflect_past("update")).to eq("updated")
    expect(subject.inflect_past("destroy")).to eq("destroyed")
    # exception:
    expect(subject.inflect_past("bite")).to eq("bitten")

    # y => ied
    expect(subject.inflect_past("buy")).to eq("bought")
    expect(subject.inflect_past("play")).to eq("played")
    expect(subject.inflect_past("curry")).to eq("curried")

    # c => ked
    expect(subject.inflect_past("picnic")).to eq("picnicked")

    # [aeigou][glmpt] => doubled
    expect(subject.inflect_past("hug")).to eq("hugged")
    expect(subject.inflect_past("stop")).to eq("stopped")
    expect(subject.inflect_past("cool")).to eq("cooled")

    # compound:
    expect(subject.inflect_past("create_user")).to eq("user_created")
    expect(subject.inflect_past("update_user")).to eq("user_updated")
    expect(subject.inflect_past("eat_picnic")).to eq("picnic_eaten")
  end
end
