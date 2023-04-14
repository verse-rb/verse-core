# frozen_string_literal: true

class CommentRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true

  field :user_id
  field :post_id

  field :content, type: String

  belongs_to :user
  belongs_to :post
end
