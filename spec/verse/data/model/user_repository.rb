require_relative "in_memory_repository"

class UserRepository < InMemoryRepository
  def self.clear
    @data.clear
    @id = 0
  end
end