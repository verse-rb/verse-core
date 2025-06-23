# frozen_string_literal: true

require_relative "lib/verse/version"

Gem::Specification.new do |spec|
  spec.name = "verse-core"
  spec.version = Verse::VERSION
  spec.authors = ["Yacine Petitprez"]
  spec.email = ["anykeyh@gmail.com"]

  spec.summary = "Base gem for the Verse Framework"
  spec.description = <<-DESC
    The Verse Framework's core gem consists of fundamental components
    such as plugin management, boot and initialization, services, effects, and
    models.

    On its own, the base gem has limited functionality, but when coupled with
    additional plugins, it becomes a much more powerful tool.
  DESC

  spec.homepage = "https://github.com/verse.rb/core"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/verse.rb/core"
  spec.metadata["changelog_uri"] = "https://github.com/verse.rb/core"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (f == __FILE__) || f.match(/\A(?:lib|sig)/)
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "verse-schema", ">= 1"
end
