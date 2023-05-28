# frozen_string_literal: true

class PostRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true, type: :int

  field :user_id

  field :title, type: :string
  field :content, type: :string

  belongs_to :user
  has_many :comments
end
