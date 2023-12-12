# frozen_string_literal: true

require_relative "category_record"

class CategoryRepository < Verse::Model::InMemory::Repository
  self.primary_key = "name"
end
