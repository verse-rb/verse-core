# frozen_string_literal: true

class CategoryRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :name, primary: true
  has_many :posts
end
