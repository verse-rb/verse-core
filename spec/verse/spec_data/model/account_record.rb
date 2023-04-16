# frozen_string_literal: true

class AccountRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true
  field :email, type: String

  enum :status, %i[active inactive]

  field :user_id

  belongs_to :user
end
