# frozen_string_literal: true

class PostRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true, type: :int

  field :user_id
  field :category_name

  field :title, type: :string
  field :content, type: :string

  field :secret_field, type: :string, visible: false

  belongs_to :user
  belongs_to :category, foreign_key: :category_name

  has_many :comments
end
