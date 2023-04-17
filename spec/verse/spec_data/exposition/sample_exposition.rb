# frozen_string_literal: true

require_relative "../service/test_service"

class SampleExposition < Verse::Exposition::Base
  desc "This is a sample exposition"

  use_service test: TestService

  @output = false

  class << self
    attr_accessor :output
  end

  expose on_spec_hook({ data: true }) do
    desc "Does something"

    input do
      required(:name).filled(:string)
      optional(:mode).filled(:symbol)
    end

    output do
      required(:name).filled(:string)
      required(:context).filled(:string)
      required(:some_data).filled(:hash)
    end
  end
  def do_something
    if params[:mode] != :unchecked
      test.some_action # This is just to test the service
    end

    self.class.output = {
      name: "#{params[:name]} Doe",
      context: context,
      some_data: some_data
    }

    self.class.output
  end
end
