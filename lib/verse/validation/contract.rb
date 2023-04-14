# frozen_string_literal: true

module Verse
  module Validation
    class Contract < Dry::Validation::Contract
      config.messages.backend = :i18n
    end
  end
end
