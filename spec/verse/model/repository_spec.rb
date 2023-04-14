# frozen_string_literal: true

require_relative "../spec_data/model/post_repository"
require_relative "../spec_data/model/user_repository"
require_relative "../spec_data/mock_auth_context"

RSpec.describe Verse::Model::Repository::Base do
  before do
    Verse.start(:server, config_path: File.join(__dir__, "../spec_data/config.yml"))

    PostRepository.clear
    UserRepository.clear

    @auth_context = MockAuthContext.new(:all)

    # create data
    @users = UserRepository.new(@auth_context)

    @users.create(name: "John")
    @users.create(name: "Jane")

    @posts = PostRepository.new(@auth_context)
    @posts.create(title: "Hello", user_id: 1)
    @posts.create(title: "World", user_id: 2)
  end

  describe "find_by" do
    it "can find user" do
      user = @users.find_by({ name: "John" })

      expect(user).to be_a(User)
      expect(user.name).to eq("John")
      expect(user.id).to eq(1)
    end

    it "returns nil if not found" do
      user = @users.find_by({ name: "Not Found" })

      expect(user).to be_nil
    end
  end

  describe "find_by!" do
    it "throws error if not found" do
      expect do
        @users.find_by!({ name: "Not Found" })
      end.to raise_error(Verse::Error::RecordNotFound)
    end
  end
end
