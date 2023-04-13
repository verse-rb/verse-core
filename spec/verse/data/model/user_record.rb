class UserRecord < Verse::Model::Record::Base
  self.record_root_path       = ""
  self.repositories_root_path = ""

  has_many :posts

  field :id, type: Integer
  field :name, type: String
end