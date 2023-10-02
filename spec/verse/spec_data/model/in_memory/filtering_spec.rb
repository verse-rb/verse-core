# frozen_string_literal: true

RSpec.describe Verse::Model::InMemory::Filtering do
  let(:collection) {
    [
      { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
      { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
      { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
      { id: 4, name: "Jane", age: 50, active: false, tags: [] },
      { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
    ]
  }

  describe "self.filter_by" do
    it "#lt" do
      out = subject.filter_by(collection, { age__lt: 30 }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "#lte" do
      out = subject.filter_by(collection, { age__lte: 30 }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
                        ])
    end

    it "#gt" do
      out = subject.filter_by(collection, { age__gt: 30 }, nil)
      expect(out).to eq([
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                          { id: 4, name: "Jane", age: 50, active: false, tags: [] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "#gte" do
      out = subject.filter_by(collection, { age__gte: 30 }, nil)
      expect(out).to eq([
                          { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                          { id: 4, name: "Jane", age: 50, active: false, tags: [] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "eq" do
      out = subject.filter_by(collection, { age: 30 }, nil)
      expect(out).to eq([
                          { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
                        ])
    end

    it "eq with array" do
      out = subject.filter_by(collection, { age: [30, 40] }, nil)
      expect(out).to eq([
                          { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                        ])
    end

    it "eq with empty array" do
      out = subject.filter_by(collection, { age: [] }, nil)
      expect(out).to eq([])
    end

    it "neq" do
      out = subject.filter_by(collection, { age__neq: 30 }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                          { id: 4, name: "Jane", age: 50, active: false, tags: [] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "prefix" do
      out = subject.filter_by(collection, { name__prefix: "Jo" }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "in" do
      out = subject.filter_by(collection, { name__in: ["John", "Jane"] }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                          { id: 4, name: "Jane", age: 50, active: false, tags: [] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "#match" do
      out = subject.filter_by(collection, { name__match: /^Jo/ }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 3, name: "John", age: 40, active: true, tags: ["a"] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "#contains" do
      out = subject.filter_by(collection, { tags__contains: "b" }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 2, name: "Jane", age: 30, active: false, tags: ["a", "b"] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "#contains with array" do
      out = subject.filter_by(collection, { tags__contains: ["b", "c"] }, nil)
      expect(out).to eq([
                          { id: 1, name: "John", age: 20, active: true, tags: ["a", "b", "c"] },
                          { id: 5, name: "John", age: 60, active: true, tags: ["a", "b", "c"] },
                        ])
    end

    it "#contains with empty array" do
      out = subject.filter_by(collection, { tags__contains: [] }, nil)
      expect(out).to eq([])
    end
  end
end
