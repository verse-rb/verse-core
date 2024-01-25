# frozen_string_literal: true

# Exposition to test event buss hooks.
class SampleExpositionEb < Verse::Exposition::Base
  class << self
    attr_accessor :something_happened
  end

  class NoAuthCheckHandler < Verse::Exposition::Handler
    def call
      exposition.auth_context.mark_as_checked!
      call_next
    end
  end

  append_handler NoAuthCheckHandler

  expose on_event "CHANNEL.spec.test" do
    input do
      field(:content, String)
    end
  end
  def on_test
    auth_context.mark_as_checked!
    SampleExpositionEb.something_happened = "on_test"
  end

  expose on_command "sum" do
    input do
      field(:numbers, Array, of: Numeric)
    end
  end
  def sum
    params[:numbers].sum
  end

  expose on_broadcast "CHANNEL.spec.broadcast" do
  end
  def something
    self.class.something_happened = true
  end
end
