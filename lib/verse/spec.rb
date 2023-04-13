require_relative "./core"

Dir["#{__dir__}/spec/**/*.rb"].each do |file|
  require_relative file
end
