# frozen_string_literal: true

class UserRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  has_many :posts
  has_many :comments
  has_one  :account

  field :id, primary: true, type: Integer
  field :name, type: String
end
