# frozen_string_literal: true

require "i18n"

module Verse
  module I18n
    extend self

    def init
      config = Verse::Config.config[:i18n] || {}

      gem_path_files = Dir[File.join(Verse::GEM_PATH, "/locales/**/*.yml")]
      ::I18n.load_path += gem_path_files

      config.fetch(:locales_paths, [File.join(Verse.root_path, "locales")]).each do |path|
        ::I18n.load_path += Dir[File.join(path, "**/*.yml")]
      end

      # remove double entry if there is any.
      ::I18n.load_path.uniq!
    end

    def load_i18n
      ::I18n.backend.load_translations
    end
  end
end
