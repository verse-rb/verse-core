# frozen_string_literal: true

require_relative "util/inflector"

module Verse
  extend self

  attr_accessor :logger, :inflector

  @inflector = Verse::Util::Inflector.new

  def environment
    @environment
  end
end
