# frozen_string_literal: true

class PostRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true, type: Integer

  field :user_id, type: Integer
  field :category_name, type: String

  field :title, type: String
  field :content, type: String

  field :secret_field, type: String, visible: false

  field :meta, type: Hash

  field :decimal_number, type: BigDecimal

  belongs_to :user, repository: "UserRepository", foreign_key: :user_id
  belongs_to :category, foreign_key: :category_name

  has_many :comments
end
