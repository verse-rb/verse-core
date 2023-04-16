# frozen_string_literal: true

require_relative "account_record"

class AccountRepository < InMemoryRepository
  primary_key :user_id
end
