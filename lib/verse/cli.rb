require_relative "./core"

Dir["#{__dir__}/cli/**/*.rb"].each do |file|
  require_relative file
end
