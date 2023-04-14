# frozen_string_literal: true

require "dry/logic"
require "dry/logic/predicates"

require "dry/schema"
require "dry/types"
require "dry/validation"

require "json"

require "dry-schema"
require "dry-types"
require "dry-validation"

module Verse
  module_function

  GEM_PATH = File.expand_path("..", __dir__)

  def service_name
    Config.config.fetch(:service_name)
  end
end

require_relative "init"
require_relative "version"
require_relative "env"

Dir["#{__dir__}/**/*.rb"].sort.each do |file|
  next if file[__dir__.size..] =~ %r{^/verse/(?:cli|spec)} # do not load CLI files unless told otherwise.

  require_relative file
end
