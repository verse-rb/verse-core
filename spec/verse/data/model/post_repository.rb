require_relative "in_memory_repository"

class PostRepository < InMemoryRepository
  def self.clear
    @data.clear
    @id = 0
  end
end
