# frozen_string_literal: true

class UserRecord < Verse::Model::Record::Base
  field :id, primary: true, type: :int
  field :name, type: String

  has_many :posts
  has_many :comments
  has_one  :account
end
