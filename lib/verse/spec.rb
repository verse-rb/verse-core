# frozen_string_literal: true

require_relative "./core"

Dir["#{__dir__}/spec/**/*.rb"].sort.each do |file|
  require_relative file
end
