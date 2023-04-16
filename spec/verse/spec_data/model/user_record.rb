# frozen_string_literal: true

class UserRecord < Verse::Model::Record::Base
  puts "load User record?"
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true, type: :int
  field :name, type: String

  has_many :posts
  has_many :comments
  has_one  :account
end
