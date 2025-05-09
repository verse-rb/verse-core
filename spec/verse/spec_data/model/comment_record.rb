# frozen_string_literal: true

class CommentRecord < Verse::Model::Record::Base
  field :id, primary: true

  field :user_id
  field :post_id

  field :content, type: :string

  belongs_to :user
  belongs_to :post
end
