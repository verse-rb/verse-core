# frozen_string_literal: true

require_relative "util/inflector"

module Verse
  @inflector = Verse::Util::Inflector.new

  class << self
    attr_accessor :logger, :inflector
    attr_reader :environment
  end
end
