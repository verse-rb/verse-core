# frozen_string_literal: true

require_relative "post_record"

class PostRepository < Verse::Model::InMemory::Repository
  custom_filter(:user_name) do |scope, value|
    ids = UserRepository.data.lazy.select{ |x| x[:name] == value }.map{ |x| x[:id] }
    scope.select{ |x| ids.include?(x[:user_id]) }
  end
end
