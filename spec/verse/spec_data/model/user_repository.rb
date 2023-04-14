# frozen_string_literal: true

require_relative "in_memory_repository"
require_relative "user_record"

class UserRepository < InMemoryRepository
  def self.clear
    @data.clear
    @id = 0
  end
end
