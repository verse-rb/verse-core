# frozen_string_literal: true

class SampleExposition < Verse::Exposition::Base
  @output = false

  class << self
    attr_accessor :output
  end

  expose on_spec_hook({ data: true }) do
    desc "Does something"

    input do
      required(:name).filled(:string)
    end
    output do
      required(:name).filled(:string)
      required(:context).filled(:string)
      required(:some_data).filled(:hash)
    end
  end
  def do_something
    self.class.output = {
      name: "#{params[:name]} Doe",
      context: context,
      some_data: some_data
    }
  end
end
