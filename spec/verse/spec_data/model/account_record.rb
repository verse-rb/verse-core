# frozen_string_literal: true

class AccountRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  field :id, primary: true
  field :email, type: String

  field :user_id

  belongs_to :user
end
