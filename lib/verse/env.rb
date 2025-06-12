# frozen_string_literal: true

require_relative "util/inflector"

module Verse
  class << self
    attr_accessor :logger
    attr_reader :environment
  end
end
