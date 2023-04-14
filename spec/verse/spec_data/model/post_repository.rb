# frozen_string_literal: true

require_relative "in_memory_repository"
require_relative "post_record"

class PostRepository < InMemoryRepository
  def self.clear
    @data.clear
    @id = 0
  end
end
