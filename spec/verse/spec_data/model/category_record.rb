# frozen_string_literal: true

class CategoryRecord < Verse::Model::Record::Base
  field :name, primary: true
  has_many :posts
end
