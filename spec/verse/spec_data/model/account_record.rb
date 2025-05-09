# frozen_string_literal: true

class AccountRecord < Verse::Model::Record::Base
  field :email, type: String

  enum :status, %i[active inactive]

  field :user_id, primary: true

  belongs_to :user
end
