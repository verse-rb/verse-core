# frozen_string_literal: true

require_relative "./class_methods"

module Verse
  module Service
    module ClassMethods
      # Define quickly repositories used by the service.
      #
      # This will automatically add metadata and propagate the
      # auth_context to the repository instance.
      #
      # Example:
      #
      # ```ruby
      # class MyService < Verse::Service::Base
      #
      #   use_repo users: UserRepository,
      #            questions: QuestionRepository
      #
      #   def do_something
      #     questions.create(content: "example")
      #   end
      # end
      # ```
      #
      # @param list_of_repositories [Hash] list of repositories to use
      def use_repo(list_of_repositories)
        unless list_of_repositories.is_a?(Hash)
          list_of_repositories = { repo: list_of_repositories }
        end

        list_of_repositories.each do |method, klass|
          define_method(method) do
            repo = instance_variable_get("@#{method}")

            return repo if repo

            repo = klass.new(auth_context)
            repo.metadata.merge!(metadata.merge(
                                   service: self.class.name
                                 ))

            instance_variable_set("@#{method}", repo)

            repo
          end
        end
      end

      alias use use_repo
    end
  end
end
