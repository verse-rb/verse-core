# frozen_string_literal: true

class AccountRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  belongs_to :user

  field :user_id

  field :id, primary: true
  field :email, type: String
end
