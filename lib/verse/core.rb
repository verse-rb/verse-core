# frozen_string_literal: true

require "verse/schema"
require "json"

module Verse
  extend self

  GEM_PATH = File.expand_path("..", __dir__)

  def service_name
    Config.config.service_name
  end
end

require_relative "./init"
require_relative "./version"
require_relative "./env"

Dir["#{__dir__}/**/*.rb"].sort.each do |file|
  next if file[__dir__.size..] =~ %r{^/(?:cli|spec)} # do not load CLI nor specs files unless told otherwise.

  require_relative file
end
