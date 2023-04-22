# frozen_string_literal: true

# Exposition to test event buss hooks.
class SampleExpositionEb < Verse::Exposition::Base

  class << self
    attr_accessor :something_happened
  end

  expose on_event "test" do
    input do
      required(:content).filled(:string)
    end
  end
  def on_test
    raise "error" unless params[:content] == "hello"
  end

  expose on_command "sum" do
    input do
      required(:numbers).array(:number?)
    end
  end
  def sum
    params[:numbers].sum
  end

  expose on_broadcast "something" do
  end
  def something
    self.class.something_happened = true
  end


end
